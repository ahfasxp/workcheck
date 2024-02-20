import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked/stacked.dart';
import 'package:workcheck/app/app.locator.dart';
import 'package:workcheck/app/app.logger.dart';
import 'package:workcheck/enums/image_layout_type.dart';
import 'package:workcheck/enums/image_resolution_type.dart';
import 'package:workcheck/services/replicate_service.dart';
import 'package:workcheck/services/shell_service.dart';

class HomeViewModel extends BaseViewModel {
  final log = getLogger('HomeViewModel');

  final _shellService = locator<ShellService>();
  final _replicateService = locator<ReplicateService>();

  Timer? _timer;
  Timer? get timer => _timer;

  List<String> _screenshots = [];
  List<String> get screenshots => _screenshots;

  String? _prediction;
  String? get prediction => _prediction;

  void init() {
    _getScreenshots();
  }

  Future<void> onStartWork() async {
    if (isBusy) return;
    log.i('Starting work');
    setBusy(true);

    try {
      _prediction = null;
      await _takeScreenshot();
      _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _takeScreenshot();
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

  Future<void> _getPrediction() async {
    if (screenshots.isEmpty) return;

    try {
      final screenShoots = await Future.wait(
        screenshots.map((path) => File(path).readAsBytes()),
      );

      final screenShootsImage = await _captureScreenShoots(screenShoots);

      if (screenShootsImage == null) return;

      final base64Image =
          "data:image/jpeg;base64,${base64Encode(screenShootsImage)}";

      final response =
          await _replicateService.createPredict(base64Image: base64Image);

      log.i('Response: $response');

      if (response.urls.stream == null) return;

      // listen stream with isolate
      final receivePort = ReceivePort();

      await Isolate.spawn(
        ReplicateService.streamPredict,
        StreamPredictArguments(
          sendPort: receivePort.sendPort,
          streamUrl: response.urls.stream!,
        ),
        onExit: receivePort.sendPort,
      );

      receivePort.listen((response) {
        log.i('Response: $response');

        _prediction = response;
        rebuildUi();

        receivePort.close();
      });
    } catch (e) {
      log.e(e);
    }
  }

  Future<Uint8List?> _captureScreenShoots(List<Uint8List> screenShoots) async {
    try {
      // Create a PictureRecorder
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);

      const imageResolutionType = ImageResolutionType.original;

      // Set a fixed height for the images
      double maxHeight = imageResolutionType.height;

      const imageLayoutType = ImageLayoutType.fourLines;

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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
