import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked.dart';
import 'package:workcheck/app/app.locator.dart';
import 'package:workcheck/app/app.logger.dart';
import 'package:workcheck/services/shell_service.dart';

class HomeViewModel extends BaseViewModel {
  final log = getLogger('HomeViewModel');

  final _shellService = locator<ShellService>();

  Timer? _timer;
  Timer? get timer => _timer;

  List<String> _screenshots = [];
  List<String> get screenshots => _screenshots;

  void init() {
    _getScreenshots();
  }

  Future<void> onStartWork() async {
    if (isBusy) return;
    log.i('Starting work');
    setBusy(true);
    await _takeScreenshot();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _takeScreenshot();
    });
    setBusy(false);
  }

  void onStopWork() {
    if (isBusy) return;
    log.i('Stopping work');
    setBusy(true);
    _timer?.cancel();
    _timer = null;
    setBusy(false);
  }

  Future<void> _takeScreenshot() async {
    log.i('Taking screenshot');
    try {
      final date = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final cacheDir = await getApplicationCacheDirectory();

      final result = await _shellService.run(
        'screencapture -x -t jpg ${cacheDir.path}/$date.jpg',
      );

      log.i(result);
      _getScreenshots();
    } catch (e) {
      log.e(e);
    }
  }

  void _getScreenshots() async {
    final cacheDir = await getApplicationCacheDirectory();
    final files = cacheDir.listSync();
    _screenshots = files
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.jpg'))
        .toList();
    _screenshots.sort();
    rebuildUi();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
