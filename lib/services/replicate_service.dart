import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:workcheck/app/app.logger.dart';
import 'package:workcheck/models/prediction_model.dart';

class ReplicateService {
  final _log = getLogger('ReplicateService');

  ReplicateService() {
    _replicateClient.options.baseUrl = _baseUrl;
    _replicateClient.options.headers = _headers;

    // add interceptor
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        _log.i('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _log.i(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _log.e(e.response);
        _log.e(
            'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        return handler.next(e);
      },
    );

    _replicateClient.interceptors.add(interceptor);
  }

  final _replicateClient = Dio();

  final String _baseUrl = 'https://api.replicate.com/v1/';
  final String _apiKey = const String.fromEnvironment('REPLICATE_API_KEY');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_apiKey',
      };

  /// yorickvp/llava-13b
  static const String _modelVersion =
      'e272157381e2a3bf12df3a8edd1f38d1dbd736bbb7437277c8b34175f8fce358';

  /// Create predict
  Future<PredictionModel> createPredict({
    required String base64Image,
  }) async {
    try {
      final response = await _replicateClient.post(
        'predictions',
        data: {
          "version": _modelVersion,
          "input": {
            "image": base64Image,
            "prompt":
                "Act as workcheck. Please make summary of the screenshot.",
            "top_p": 1,
            "max_tokens": 200,
            "temperature": 0.2
          },
          "stream": true,
        },
      );

      return PredictionModel.fromJson(response.data);
    } on DioException catch (e) {
      _log.e(e);
      throw e.message ?? 'An unknown error occurred.';
    } catch (e) {
      _log.e(e);
      throw 'An unknown error occurred.';
    }
  }

  /// Stream predict with isolate
  static void streamPredict(StreamPredictArguments args) async {
    final logger = getLogger('ReplicateService');

    try {
      // request dio with full url
      final response = await Dio().get<ResponseBody>(
        args.streamUrl,
        options: Options(
          headers: {
            'accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      final result = StringBuffer();

      bool isDone = false;

      StreamTransformer<Uint8List, List<int>> unit8Transformer =
          StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(List<int>.from(data));
        },
      );

      response.data?.stream
          .transform(unit8Transformer)
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen(
        (event) {
          logger.i(event);

          if (isDone) {
            return;
          }

          if (event.contains("event: done")) {
            isDone = true;
          }

          if (event.contains("data: ")) {
            final data = event.split('data: ').last;
            result.write(data);
          }
        },
        onDone: () {
          args.sendPort.send(result.toString());
        },
      );
    } on DioException catch (e) {
      logger.e(e);
      throw e.message ?? 'An unknown error occurred.';
    } catch (e) {
      logger.e(e);
      throw 'An unknown error occurred.';
    }
  }
}

class StreamPredictArguments {
  final SendPort sendPort;
  final String streamUrl;

  StreamPredictArguments({
    required this.sendPort,
    required this.streamUrl,
  });
}
