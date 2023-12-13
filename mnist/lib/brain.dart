import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' hide Image;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as im;
import 'package:mnist/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class AppBrain {
  late tfl.Interpreter interpreter;

  Future<void> loadModel() async {
    try {
      interpreter = await tfl.Interpreter.fromAsset(
          'assets/converted_mnist_model.tflite');
    } catch (err) {
      print(err);
    }
  }

  Future processCanvasPoints(List<Offset?> points) async {
    const canvasSizeWithPadding = kCanvasSize + (2 * kCanvasInnerOffset);
    const canvasOffset = Offset(kCanvasInnerOffset, kCanvasInnerOffset);
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        const Offset(0, 0),
        const Offset(canvasSizeWithPadding, canvasSizeWithPadding),
      ),
    );

    canvas.drawRect(
        const Rect.fromLTWH(0, 0, canvasSizeWithPadding, canvasSizeWithPadding),
        kBackgroundPaint);

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]! + canvasOffset,
            points[i + 1]! + canvasOffset, kWhitePaint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
        canvasSizeWithPadding.toInt(), canvasSizeWithPadding.toInt());

    final imgBytes = await img.toByteData(format: ImageByteFormat.png);
    Uint8List pngUint8List = imgBytes!.buffer.asUint8List();

    im.Image imImage = im.decodeImage(pngUint8List)!;
    im.Image resizedImage =
        im.copyResize(imImage, width: kModelInputSize, height: kModelInputSize);

    final Directory tempDir = await getTemporaryDirectory();
    File imgfile = File('${tempDir.path}/hello.png');
    imgfile.writeAsBytes(im.encodePng(resizedImage));

    List grayImg =
        imageToGray(resizedImage, kModelInputSize).reshape([1, 28, 28]);

    return predictImage(grayImg);
    //return predictImage(resizedImage);
  }

  // Future<List> predictImage(im.Image image) async {}

  Float32List imageToGray(im.Image image, int inputSize) {
    var convertedBytes = Float32List(inputSize * inputSize);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (final p in image) {
      buffer[pixelIndex++] = (p.r + p.g + p.b) / 3 / 255.0;
    }
    return convertedBytes;
  }

  List predictImage(List imageInput) {
    List output = List.filled(10, 0).reshape([1, 10]);
    interpreter.run(imageInput, output);
    return output;
  }
}
