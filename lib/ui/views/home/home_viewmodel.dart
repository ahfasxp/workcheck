import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:workcheck/app/app.locator.dart';
import 'package:workcheck/app/app.logger.dart';
import 'package:workcheck/enums/image_layout_type.dart';
import 'package:workcheck/enums/image_resolution_type.dart';
import 'package:workcheck/models/prediction_result_model.dart';
import 'package:workcheck/services/open_ai_service.dart';
import 'package:workcheck/services/prediction_service.dart';
import 'package:workcheck/services/shell_service.dart';

class HomeViewModel extends ReactiveViewModel {
  final log = getLogger('HomeViewModel');

  final _shellService = locator<ShellService>();
  final _predictionService = locator<PredictionService>();
  final _dialogService = locator<DialogService>();
  final _openAiService = locator<OpenAiService>();

  Timer? _timer;
  Timer? get timer => _timer;

  List<String> _screenshots = [];
  List<String> get screenshots => _screenshots;

  List<PredictionResultModel> get predictionResults =>
      _predictionService.predictionResults;

  String? _summaryOfToday;
  String? get summaryOfToday => _summaryOfToday;

  void init() {
    _getScreenshots();

    _predictionService.startStreamByDeviceId();
  }

  Future<void> onStartWork() async {
    if (isBusy) return;
    log.i('Starting work');
    setBusy(true);

    try {
      await _deleteScreenshots();

      _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_screenshots.length > 5) {
          await _getPrediction();
        } else {
          await _takeScreenshot();
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

      _predictionService.runPredict(base64Image: base64Image);

      await _deleteScreenshots();
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

      const imageResolutionType = ImageResolutionType.original;

      // Set a fixed height for the images
      double maxHeight = imageResolutionType.height;

      final imageLayoutType = screenShoots.length < 3
          ? ImageLayoutType.oneLine
          : ImageLayoutType.twoLines;

      double? minOffsetDx;
      double? minOffsetDy;

      double maxOffsetDx = 0;
      double maxOffsetDy = 0;

      for (Uint8List bytes in screenShoots) {
        ui.Codec codec = await ui.instantiateImageCodec(bytes);
        ui.FrameInfo frameInfo = await codec.getNextFrame();
        ui.Image image = frameInfo.image;

        if (imageResolutionType.isOriginal) {
          maxHeight = image.height.toDouble();
        }

        int imageIndex = screenShoots.indexOf(bytes);

        double scaleFactor = maxHeight / image.height;
        double scaledWidth = image.width * scaleFactor;
        double scaledHeight = image.height * scaleFactor;

        final offset = imageLayoutType.getOffset(
          index: imageIndex,
          totalImages: screenShoots.length,
          scaledWidth: scaledWidth,
        );

        if (offset.dx != 0.0) {
          minOffsetDx = min(offset.dx, minOffsetDx ?? offset.dx);
        }

        if (offset.dy != 0.0) {
          minOffsetDy = min(offset.dy, minOffsetDy ?? offset.dy);
        }

        maxOffsetDx = max(offset.dx, maxOffsetDx);
        maxOffsetDy = max(offset.dx, maxOffsetDy);

        canvas.drawImageRect(
          image,
          Rect.fromLTRB(
              0.0, 0.0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromPoints(
            offset,
            Offset(offset.dx + scaledWidth, offset.dy + scaledHeight),
          ),
          Paint(),
        );
      }

      final totalImageWidth = maxOffsetDx + minOffsetDx!;

      final totalImageHeight =
          (minOffsetDy ?? (minOffsetDx * .5)) * imageLayoutType.lines;

      // End recording and obtain the picture
      ui.Picture picture = recorder.endRecording();

      // Convert the picture into a rasterized image
      ui.Image finalImage = await picture.toImage(
        totalImageWidth.round(),
        totalImageHeight.round(),
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

  Future<void> getSummaryOfToday() async {
    if (busy('getSummaryOfToday')) return;
    setBusyForObject('getSummaryOfToday', true);

    _summaryOfToday = null;

    try {
      // today 00:00
      final from = DateTime.now().add(
        Duration(
          hours: -DateTime.now().hour,
          minutes: -DateTime.now().minute,
          seconds: -DateTime.now().second,
        ),
      );
      // today 23:59
      final to = DateTime.now().add(
        Duration(
          hours: 23 - DateTime.now().hour,
          minutes: 59 - DateTime.now().minute,
          seconds: 59 - DateTime.now().second,
        ),
      );

      final descriptions = await _predictionService.getDescriptions(
        from: from,
        to: to,
      );

      if (descriptions.isEmpty) {
        throw 'There are no descriptions for today. Please wait for the next prediction.';
      }

      _summaryOfToday = await _openAiService.getSummaryOfToday(descriptions);
    } catch (e) {
      log.e(e);

      await _dialogService.showDialog(
        description: e.toString(),
      );
    } finally {
      setBusyForObject('getSummaryOfToday', false);
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
