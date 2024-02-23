import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workcheck/app/app.logger.dart';
import 'package:workcheck/enums/pg_table_type.dart';

class DeviceService {
  final _log = getLogger('DeviceService');

  final _supabase = Supabase.instance.client;

  final _deviceInfo = DeviceInfoPlugin();

  Future<void> save() async {
    try {
      final deviceId = await FlutterUdid.consistentUdid;
      final device = await _deviceInfo.macOsInfo;

      await _supabase.from(PgTableType.devices.name).upsert({
        'id': deviceId,
        'name': device.computerName,
      });
    } on PostgrestException catch (e) {
      _log.e(e);
    } catch (e) {
      _log.e(e);
    }
  }
}
