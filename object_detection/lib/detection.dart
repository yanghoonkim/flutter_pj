import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as im;

class ObjectDetection {
  late tfl.Interpreter interpreter;
  late List _labels;

  ObjectDetection() {
    loadModel();
    getLabel();
  }

  void loadModel() async {
    interpreter =
        await tfl.Interpreter.fromAsset('assets/ssd_mobilenet.tflite');
  }

  void getLabel() async {
    var labels = await rootBundle.loadString('assets/labelmap.txt');
    _labels = labels.split('\n');
  }

  Future<List> processImage(String imgPath) async {
    File imgFile = File(imgPath);
    Uint8List imageBytes = await imgFile.readAsBytes();
    im.Image image = im.decodeImage(Uint8List.fromList(imageBytes))!;
    im.Image resizedImage = im.copyResize(image, width: 300, height: 300);
    List<List> rgbMatrix = [];
    for (int y = 0; y < resizedImage.height; y++) {
      List row = [];
      for (int x = 0; x < resizedImage.width; x++) {
        var pixel = resizedImage.getPixel(x, y);
        final red = pixel.r;
        final green = pixel.g;
        final blue = pixel.b;
        row.add([red, green, blue]);
      }
      rgbMatrix.add(row);
    }

    return [image, rgbMatrix];
  }

  Future<List> inference(String imgPath) async {
    var processed = await processImage(imgPath);
    var image = processed[0];
    var rgbMatrix = processed[1];
    var input = [rgbMatrix];
    final output = {
      0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
      1: [List<num>.filled(10, 0)],
      2: [List<num>.filled(10, 0)],
      3: [0.0]
    };

    interpreter.runForMultipleInputs([input], output);
    return [image, output];
  }

  Future<Uint8List> detect(String imgPath) async {
    var processed = await inference(imgPath);
    im.Image image = processed[0];
    Map output = processed[1];

    // image resize
    int scaleFactor = 1;
    int width = image.width;
    print(image.width);
    while (image.width / scaleFactor > 1000) {
      scaleFactor++;
    }
    image = im.copyResize(image,
        width: (image.width / scaleFactor).round(),
        height: (image.height / scaleFactor).round());

    // draw rectangles
    int numberOfDetection = output[3][0].toInt();

    // get labels
    List classes = output[1][0].map((value) => _labels[value.toInt()]).toList();

    for (var i = 0; i < numberOfDetection; i++) {
      double score = output[2][0][i];
      if (score >= 0.6) {
        int x1 = (output[0][0][i][1] * image.width).round();
        int x2 = (output[0][0][i][3] * image.width).round();
        int y1 = (output[0][0][i][0] * image.height).round();
        int y2 = (output[0][0][i][2] * image.height).round();
        im.drawRect(image,
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            color: im.ColorRgb8(255, 0, 0),
            thickness: 3);

        im.drawString(image, '${classes[i]}, score: $score',
            font: im.arial24,
            x: x1 + 1,
            y: y1 + 1,
            color: im.ColorRgb8(255, 0, 0));
      }
    }

    return im.encodeJpg(image);
  }
}
