import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked.dart';
import 'package:workcheck/app/app.locator.dart';
import 'package:workcheck/app/app.logger.dart';
import 'package:workcheck/models/prediction_result_model.dart';
import 'package:workcheck/services/device_service.dart';
import 'package:workcheck/services/prediction_service.dart';
import 'package:workcheck/services/shell_service.dart';

class HomeViewModel extends ReactiveViewModel {
  final log = getLogger('HomeViewModel');

  final _shellService = locator<ShellService>();
  final _predictionService = locator<PredictionService>();
  final _deviceService = locator<DeviceService>();

  Timer? _timer;
  Timer? get timer => _timer;

  List<String> _screenshots = [];
  List<String> get screenshots => _screenshots;

  List<PredictionResultModel> get predictionResults =>
      _predictionService.predictionResults;

  void init() {
    _deviceService.save();
    _getScreenshots();
    _predictionService.startStreamByDeviceId();
  }

  Future<void> onStartWork() async {
    if (isBusy) return;
    log.i('Starting work');
    setBusy(true);

    try {
      await _deleteScreenshots();

      _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        await _takeScreenshot();
        if (_screenshots.length > 3) {
          await _getPrediction();
        }
      });
    } catch (e) {
      log.e(e);
    }

    setBusy(false);
  }

  Future<void> onStopWork() async {
    if (isBusy) return;
    log.i('Stopping work');
    setBusy(true);

    try {
      _timer?.cancel();
      _timer = null;
      await _getPrediction();
    } catch (e) {
      log.e(e);
    }

    setBusy(false);
  }

  Future<void> _takeScreenshot() async {
    log.i('Taking screenshot');
    try {
      final date = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final cacheDir = await getApplicationCacheDirectory();

      await _shellService.run(
        'screencapture -x -t jpg ${cacheDir.path}/$date.jpg',
      );

      await _getScreenshots();
    } catch (e) {
      log.e(e);
    }
  }

  Future<void> _getScreenshots() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final files = cacheDir.listSync();
      _screenshots = files
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith('.jpg'))
          .toList();
      _screenshots.sort();
      rebuildUi();
    } catch (e) {
      log.e(e);
    }
  }

  Future<void> _deleteScreenshots() async {
    try {
      _screenshots = [];
      // delete all screenshots
      final cacheDir = await getApplicationCacheDirectory();
      for (final file in cacheDir.listSync()) {
        if (file is File && file.path.endsWith('.jpg')) {
          file.delete();
        }
      }
    } catch (e) {
      log.e(e);
    }
  }

  Future<void> _getPrediction() async {
    if (_screenshots.isEmpty) return;

    try {
      final screenShoots = await Future.wait(
        _screenshots.map((path) => File(path).readAsBytes()),
      );

      final screenShootsImage = screenShoots.length == 1
          ? screenShoots.first
          : await _captureScreenShoots(screenShoots);

      if (screenShootsImage == null) return;

      final base64Image =
          "data:image/jpeg;base64,${base64Encode(screenShootsImage)}";

      await _deleteScreenshots();

      await _predictionService.runPredict(base64Image: base64Image);
    } catch (e) {
      log.e(e);
    }
  }

  Future<Uint8List?> _captureScreenShoots(List<Uint8List> screenShoots) async {
    log.i('ScreenShoots: ${screenShoots.length}');

    try {
      // Create a PictureRecorder
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);

      // Draw each image onto the canvas with padding
      double currentOffset = 0.0;
      double padding = 10.0; // Adjust the padding as needed
      double maxHeight = 0.0;

      for (Uint8List bytes in screenShoots) {
        ui.Codec codec = await ui.instantiateImageCodec(bytes);
        ui.FrameInfo frameInfo = await codec.getNextFrame();
        ui.Image image = frameInfo.image;

        // Calculate the maximum height
        if (image.height.toDouble() > maxHeight) {
          maxHeight = image.height.toDouble();
        }

        canvas.drawImage(image, Offset(currentOffset, 0.0), Paint());
        currentOffset += image.width.toDouble() + padding;
      }

      // Calculate the total width needed
      double totalWidth = currentOffset - padding;

      // End recording and obtain the picture
      ui.Picture picture = recorder.endRecording();

      // Convert the picture into a rasterized image
      ui.Image finalImage = await picture.toImage(
        totalWidth.round(), // Use the calculated total width
        maxHeight.round(), // Set the height to the maximum height
      );

      // Convert the image into bytes
      ByteData? byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);

      // Return the image data as Uint8List
      return byteData?.buffer.asUint8List();
    } catch (e) {
      log.e('Error capturing screenshot: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _predictionService.disposeStream();
    super.dispose();
  }

  @override
  List<ListenableServiceMixin> get listenableServices => [_predictionService];
}
