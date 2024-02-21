import 'package:dio/dio.dart';
import 'package:workcheck/app/app.logger.dart';

class OpenAiService {
  final _log = getLogger('OpenAiService');

  OpenAiService() {
    _openAIClient.options.baseUrl = _baseUrl;
    _openAIClient.options.headers = _headers;

    _openAIClient.interceptors.add(
      InterceptorsWrapper(
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
      ),
    );
  }

  final _openAIClient = Dio();

  final String _baseUrl = 'https://api.openai.com/v1/chat/';
  final String _apiKey = const String.fromEnvironment('OPENAI_API_KEY');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

  Future<String> getSummaryOfToday(List<String> descriptions) async {
    try {
      final prompt =
          'Generate a summary of today\'s events based on the following descriptions. Give a brief overview of what was done throughout the day.\n\n${descriptions.join('\n\n')}';

      final response = await _openAIClient.post(
        'completions',
        data: {
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 500,
          'n': 1,
          'temperature': 1.0,
        },
      );

      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      _log.e(e);
      rethrow;
    }
  }
}
