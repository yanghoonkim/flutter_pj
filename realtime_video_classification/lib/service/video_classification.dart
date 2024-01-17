import 'dart:isolate';

import 'package:circular_buffer/circular_buffer.dart';
import 'package:dart_tensor/dart_tensor.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

class VideoClassification {
  static late IsolateInterpreter isolateInterpreter;
  static late List<String> labels;
  static bool isReady = false;

  static late List<Tensor> inputTensors;
  static late List<Tensor> outputTensors;

  static DartTensor dt = DartTensor();

  static Future<void> loadModelLabels() async {
    // load AI model
    final interpreter =
        await Interpreter.fromAsset('assets/movinet_a0_int8.tflite');
    isolateInterpreter =
        await IsolateInterpreter.create(address: interpreter.address);

    // load labels
    labels = (await rootBundle.loadString('assets/kinetics600_label_map.txt'))
        .split('\n');

    inputTensors = interpreter.getInputTensors();
    outputTensors = interpreter.getOutputTensors();
  }

  static void initInputsOutputs() {
    // input (type이 int32/float32 둘 중 하나라는 것을 이미 확인 함)
    final inputs = [];
    for (final tensor in inputTensors) {
      final dtype = tensor.type == TensorType.float32 ? 'float' : 'int';
      final currentTensor = dt.utils.zeros(tensor.shape, dtype: dtype);
      inputs.add(currentTensor);
    }

    // [1, 1, 172, 172, 3]
    inputs[37] = 0;

    final outputs = [];
    for (final tensor in outputTensors) {}
  }

  static void runModel(CircularBuffer<imglib.Image> images) {
    // 처리하는 중에는 isReady를 false로 설정
    isReady = false;
  }
}
