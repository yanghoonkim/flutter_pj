import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realtime_object_detection/models/recognition.dart';
import 'package:realtime_object_detection/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as image_lib;

enum Codes { ready, detect, busy, result }

class Command {
  Codes code;
  List? args;

  Command(this.code, this.args);
}

class RootIsolate {
  // root -> background
  static late SendPort sendPort;
  static late tfl.Interpreter interpreter;
  static late List<String> labels;
  static bool isReady = false;

  static StreamController resultStream = StreamController();

  static Future<void> start() async {
    ReceivePort receivePort = ReceivePort();
    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    await loadModelAndLabels();
    Isolate isolate = await Isolate.spawn(BackgroundIsolate.start,
        [receivePort.sendPort, rootIsolateToken, interpreter.address, labels]);
    receivePort.listen((message) {
      handleCommand(message);
    });
  }

  static Future<void> loadModelAndLabels() async {
    interpreter =
        await tfl.Interpreter.fromAsset('assets/models/ssd_mobilenet.tflite');

    labels =
        (await rootBundle.loadString('assets/models/labelmap.txt')).split('\n');
  }

  static void handleCommand(Command command) {
    switch (command.code) {
      case Codes.ready:
        sendPort = command.args![0];
        isReady = true;
      case Codes.busy:
        isReady = false;
      case Codes.result:
        isReady = true;
        resultStream.add(command.args!);

      default:
        debugPrint('Unrecognized code for RootIsolate: ${command.code}');
    }
  }

  static processFrame(CameraImage cameraImage) {
    if (isReady) {
      sendPort.send(Command(Codes.detect, [cameraImage]));
    }
  }
}

class BackgroundIsolate {
  static late tfl.Interpreter interpreter;
  static late List<String> labels;

  static late SendPort sendPort;

  static int mlModelInputSize = 300;

  static const double confidence = 0.5;

  static void start(List args) {
    sendPort = args[0];
    RootIsolateToken rootIsolateToken = args[1];
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    interpreter = tfl.Interpreter.fromAddress(args[2]);
    labels = args[3];

    ReceivePort receivePort = ReceivePort();
    receivePort.listen((message) {
      handleCommand(message);
    });
    Command firstCommand = Command(Codes.ready, [receivePort.sendPort]);
    sendPort.send(firstCommand);
  }

  static void handleCommand(Command command) {
    switch (command.code) {
      case Codes.detect:
        sendPort.send(Command(Codes.busy, []));
        getResult(command.args![0]);
      default:
        debugPrint('Unrecognized code for BackgroundIsolate: ${command.code}');
    }
  }

  static void getResult(CameraImage cameraImage) {
    convertCameraImageToImage(cameraImage).then((image) {
      if (image != null) {
        if (Platform.isAndroid) {
          // 일단 알아야 할 정보는 ios 든 android든 controller.previewSize는 모두 landscape
          // 하지만 imageStream의 경우 ios는 자동으로 portrait로 바꿔주는 반면 android는 그렇지 않다
          image = image_lib.copyRotate(image, angle: 90);
        }

        final results = analyseImage(image);
        sendPort.send(Command(Codes.result, [results, image]));
      }
    });
  }

  static List<Recognition> analyseImage(image_lib.Image image) {
    /// Pre-process the image
    /// Resizing image for model [300, 300]
    final imageInput = image_lib.copyResize(
      image,
      width: mlModelInputSize,
      height: mlModelInputSize,
    );

    // Creating matrix representation, [300, 300, 3]
    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    final output = _runInference(imageMatrix);

    // Location
    final locationsRaw = output.first.first as List<List<double>>;

    final List<Rect> locations = locationsRaw
        .map((list) => list.map((value) => (value * mlModelInputSize)).toList())
        .map((rect) => Rect.fromLTRB(rect[1], rect[0], rect[3], rect[2]))
        .toList();

    // Classes
    final classesRaw = output.elementAt(1).first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();

    // Scores
    final scores = output.elementAt(2).first as List<double>;

    // Number of detections
    final numberOfDetectionsRaw = output.last.first as double;
    final numberOfDetections = numberOfDetectionsRaw.toInt();

    final List<String> classification = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classification.add(labels[classes[i]]);
    }

    // results with confidence
    List<Recognition> recognitions = <Recognition>[];
    for (int i = 0; i < numberOfDetections; i++) {
      if (scores[i] > confidence) {
        recognitions
            .add(Recognition(classification[i], scores[i], locations[i]));
      }
    }

    return recognitions;
  }

  /// Object detection main function
  static List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) {
    // Set input tensor [1, 300, 300, 3]
    final input = [imageMatrix];

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final output = {
      0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
      1: [List<num>.filled(10, 0)],
      2: [List<num>.filled(10, 0)],
      3: [0.0],
    };

    interpreter.runForMultipleInputs([input], output);
    return output.values.toList();
  }
}
