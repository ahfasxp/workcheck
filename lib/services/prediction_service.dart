import 'package:flutter_udid/flutter_udid.dart';
import 'package:stacked/stacked.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workcheck/app/app.logger.dart';
import 'package:workcheck/enums/pg_table_type.dart';
import 'package:workcheck/models/prediction_result_model.dart';

class PredictionService with ListenableServiceMixin {
  PredictionService() {
    listenToReactiveValues([
      _predictionResults,
    ]);
  }

  final _log = getLogger('PredictionService');

  final _supabase = Supabase.instance.client;

  RealtimeChannel? _realtimeChannel;

  final _predictionResults = ReactiveList<PredictionResultModel>();
  List<PredictionResultModel> get predictionResults =>
      _predictionResults.toList();

  /// Run predict
  Future<void> runPredict({
    required String base64Image,
  }) async {
    try {
      final deviceId = await FlutterUdid.consistentUdid;

      final body = {
        "deviceId": deviceId,
        "model":
            "yorickvp/llava-13b:a0fdc44e4f2e1f20f2bb4e27846899953ac8e66c5886c5878fa1d6b73ce009e5",
        "input": {
          "image": base64Image,
          "prompt": "Act as workcheck. Please make summary of the screenshot.",
          "top_p": 1,
          "max_tokens": 200,
          "temperature": 0.2
        },
      };

      await _supabase.functions.invoke(
        'replicate-run-prediction',
        body: body,
      );
    } on FunctionException catch (e) {
      _log.e(e);
      throw e.details ?? 'An unknown error occurred.';
    } catch (e) {
      _log.e(e);
      throw 'An unknown error occurred.';
    }
  }

  Future<void> startStreamByDeviceId(String deviceId) async {
    _log.wtf('startStreamByDeviceId: $deviceId');

    _predictionResults.clear();

    // get all prediction results
    final response = await _supabase
        .from(PgTableType.predictionResults.name)
        .select()
        .eq('device_id', deviceId)
        .order('created_at', ascending: true);

    for (final json in response) {
      final predictionResult = PredictionResultModel.fromJson(json);
      _predictionResults.add(predictionResult);
    }

    _realtimeChannel = _supabase
        .channel('prediction_result')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: PgTableType.predictionResults.name,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_id',
            value: deviceId,
          ),
          callback: (payload) {
            _log.wtf('payload: $payload');

            final predictionResult = PredictionResultModel.fromJson(
              payload.newRecord,
            );

            _predictionResults.add(predictionResult);
          },
        )
        .subscribe((status, e) {
      _log.i('status: $status');
      if (e != null) _log.i('e: $e');
    });
  }

  void disposeStream() {
    _log.wtf('disposeStream');

    _realtimeChannel?.unsubscribe();
  }
}
