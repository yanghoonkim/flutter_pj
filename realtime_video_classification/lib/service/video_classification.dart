import 'dart:io';
import 'dart:isolate';

import 'package:circular_buffer/circular_buffer.dart';
import 'package:dart_tensor/dart_tensor.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realtime_video_classification/constants.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import 'dart:math' as math;

class VideoClassification {
  static late IsolateInterpreter isolateInterpreter;
  static late List<String> labels;
  static bool isReady = false;

  static late List<Tensor> inputTensors;
  static late List<Tensor> outputTensors;

  static DartTensor dt = DartTensor();

  static Future<void> loadModelLabels() async {
    final interpreterOptions = InterpreterOptions();
    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // load AI model
    final interpreter = await Interpreter.fromAsset(
      'assets/movinet_a0_int8.tflite',
      options: interpreterOptions..threads = 4,
    );
    isolateInterpreter =
        await IsolateInterpreter.create(address: interpreter.address);

    // load labels
    labels = (await rootBundle.loadString('assets/kinetics600_label_map.txt'))
        .split('\n');

    inputTensors = interpreter.getInputTensors();
    outputTensors = interpreter.getOutputTensors();
    //print(interpreter.getOutputTensor(43));
    //print('hello');
  }

  static (List<Object>, Map<int, Object>) initInputsOutputs(
      List<List<List<double>>> image) {
    // input (type이 int32/float32 둘 중 하나라는 것을 이미 확인 함)
    var inputs = <Object>[];
    //for (final idx in inputIndexOrder) {
    //  final currentTensor =
    //      dt.utils.zeros(inputTensors[idx].shape, dtype: 'double');
    //  inputs.add(currentTensor);
    //}

    for (var tensor in inputTensors) {
      String dtype = tensor.type == 'float32' ? 'double' : 'int';
      var currentTensor = dt.utils.zeros(tensor.shape, dtype: dtype);
      inputs.add(currentTensor);
    }

    // [1, 1, 172, 172, 3]
    inputs[37] = [
      [image]
    ];

    var outputs = <int, Object>{};
    //for (final (i, idx) in inputIndexOrder.indexed) {
    //  final currentTensor =
    //      dt.utils.zeros(inputTensors[idx].shape, dtype: 'double');
    //  outputs[i] = currentTensor;
    //}
    //outputs[0] = dt.utils.zeros([1, 600], dtype: 'double');

    for (var (idx, tensor) in outputTensors.indexed) {
      //String dtype = tensor.type == 'float32' ? 'double' : 'int';
      var currentTensor = dt.utils.zeros(tensor.shape, dtype: 'double');
      outputs[idx] = currentTensor;
    }

    return (inputs, outputs);
  }

  static (List<Object>, Map<int, Object>) processInputOutput(
      List<List<List<double>>> image, Map<int, Object> previousOutput) {
    var inputs = previousOutput.values.toList();
    inputs.removeAt(10);
    inputs.insert(37, [
      [image]
    ]);

    // change dtype of inputs
    for (var (i, tensor) in inputTensors.indexed) {
      if (tensor.type == 'int32') {
        dt.utils.changeDtype(inputs[i] as List<dynamic>, 'int');
      }
    }

    var outputs = <int, Object>{};
    for (var (idx, tensor) in outputTensors.indexed) {
      //String dtype = tensor.type == 'float32' ? 'double' : 'int';
      var currentTensor = dt.utils.zeros(tensor.shape, dtype: 'double');
      outputs[idx] = currentTensor;
    }

    outputs = previousOutput;

    return (inputs, outputs);
  }

  static Future<imglib.Image> runModelTemp() async {
    //final ImagePicker picker = ImagePicker();
    //final XFile? pickedFile =
    //    await picker.pickImage(source: ImageSource.gallery);

    //File gifFile = File(pickedFile!.path);

    // Read the file as bytes
    final ByteData data = await rootBundle.load('assets/jumpingjack.gif');
    Uint8List bytes = data.buffer.asUint8List();
    //Uint8List bytes = await gifFile.readAsBytes();

    // Decode the GIF animation
    imglib.Image? animation = imglib.decodeGif(bytes);
    List<imglib.Image> frames_ = animation!.frames;
    List<imglib.Image> frames = animation.frames;
    //for (var (i, item) in frames.indexed) {
    //  frames[i] = removePalette(item);
    //}

    var images = processs(frames);
    isReady = false;

    // the first input
    var (inputs, outputs) = initInputsOutputs(images[0]);
    await isolateInterpreter.runForMultipleInputs(inputs, outputs);

    var states = outputs;

    // inputs remained
    for (var image in images.sublist(1)) {
      var (inputs, outputs) = processInputOutput(image, states);
      await isolateInterpreter.runForMultipleInputs(inputs, outputs);
      states = outputs;
    }

    var logits = outputs[10] as List<List<dynamic>>;
    var probs = softmax(logits[0] as List<double>);

    // get max probs with its index
    double maxValue = probs[0];
    int maxIndex = 0;

    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxValue) {
        maxValue = probs[i];
        maxIndex = i;
      }
    }

    print(maxValue);
    print(labels[maxIndex]);
    print('hello world');

    List finalImages = [];
    List<int> tgif = <int>[];
    imglib.Image gifImage = imglib.Image(width: 172, height: 172);
    for (var image in frames_) {
      imglib.Image resizedImage = imglib.copyResize(image,
          width: mlModelInputSize,
          height: mlModelInputSize,
          interpolation: imglib.Interpolation.average);
      finalImages.add(resizedImage);
      gifImage.addFrame(resizedImage);
      tgif = tgif + Uint8List.fromList(resizedImage.toUint8List());
    }

    //Uint8List tgif = Uint8List.fromList(finalImages.map((e)=>imglib.encodeGif(e)).toList());
    gifImage.frames.sublist(1);
    Uint8List gif = imglib.encodeGif(gifImage);
    final Directory downloadsDir = await getApplicationDocumentsDirectory();
    String tempFilePath =
        '${downloadsDir.path}/${DateTime.now().millisecondsSinceEpoch}.gif';
    File file = File(tempFilePath);
    file.writeAsBytesSync(gif);
    // Return XFile from the temporary file path
    final imagetook_ = XFile(file.path);

    await GallerySaver.saveImage(imagetook_.path);
    print('what');
    return animation;
  }

  static Future runModel(
      CircularBuffer<List<List<List<double>>>> images) async {
    // 처리하는 중에는 isReady를 false로 설정
    isReady = false;

    // the first input
    var (inputs, outputs) = initInputsOutputs(images[0]);
    await isolateInterpreter.runForMultipleInputs(inputs, outputs);

    var states = outputs;

    // inputs remained
    for (var image in images.sublist(1)) {
      var (inputs, outputs) = processInputOutput(image, states);
      await isolateInterpreter.runForMultipleInputs(inputs, outputs);
      states = outputs;
    }

    var logits = outputs[10] as List<List<dynamic>>;
    var probs = softmax(logits[0] as List<double>);

    // get max probs with its index
    double maxValue = probs[0];
    int maxIndex = 0;

    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxValue) {
        maxValue = probs[i];
        maxIndex = i;
      }
    }
    print(labels[maxIndex]);
    return (maxValue, labels[maxIndex]);
  }
}

List<double> softmax(List<double> logits) {
  // Step 1: Find the maximum value in the logits to use for normalization
  final double maxLogit = logits.reduce(math.max);

  // Step 2: Exponentiate each logit and normalize by the sum of all exponentiated logits
  // This prevents overflow issues when exponentiating large numbers
  final List<double> expLogits =
      logits.map((logit) => math.exp(logit - maxLogit)).toList();

  // Step 3: Calculate the sum of the exponentiated and normalized logits
  final double sumExpLogits = expLogits.reduce((a, b) => a + b);

  // Step 4: Normalize each exponentiated logit by the sum to get the probability distribution
  final List<double> probabilities =
      expLogits.map((expLogit) => expLogit / sumExpLogits).toList();

  return probabilities;
}

List processs(List<imglib.Image> images) {
  List finalImages = [];
  for (var image in images) {
    imglib.Image resizedImage = imglib.copyResize(
      image,
      width: mlModelInputSize,
      height: mlModelInputSize,
    );

    // Creating normalized matrix representation, [172, 172, 3]
    var imageMatrix = List.generate(
      resizedImage.height,
      (y) => List.generate(
        resizedImage.width,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r / 255, pixel.g / 255, pixel.b / 255];
        },
      ),
    );
    //finalImages.add(normalizeImageMatrix(imageMatrix));
    finalImages.add(imageMatrix);
  }

  return finalImages;
}

imglib.Image removePalette(imglib.Image src) {
  if (!src.hasPalette) {
    return src; // If the image doesn't have a palette, return it as is.
  }

  // Create a new image with the same dimensions as the source.
  imglib.Image newImage = imglib.Image(width: src.width, height: src.height);

  // Copy each pixel from the source image to the new image.
  for (int y = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width; ++x) {
      newImage.setPixel(x, y, src.getPixel(x, y));
    }
  }

  return newImage;
}

List<List<List<double>>> normalizeImageMatrix(
    List<List<List<num>>> imageMatrix) {
  int height = imageMatrix.length;
  int width = imageMatrix[0].length;

  // Initialize sums and squares for each channel to calculate mean and std dev
  List<double> sum = [0.0, 0.0, 0.0];
  List<double> sumOfSquares = [0.0, 0.0, 0.0];
  int totalPixels = width * height;

  // Sum up the values and the squares of the values for each channel
  for (var row in imageMatrix) {
    for (var pixel in row) {
      for (int channel = 0; channel < 3; channel++) {
        sum[channel] += pixel[channel];
        sumOfSquares[channel] += math.pow(pixel[channel], 2);
      }
    }
  }

  // Calculate mean and std for each channel
  List<double> mean = List.generate(3, (i) => sum[i] / totalPixels);
  List<double> std = List.generate(3,
      (i) => math.sqrt((sumOfSquares[i] / totalPixels) - math.pow(mean[i], 2)));

  // Normalize the image matrix
  List<List<List<double>>> normalizedMatrix = List.generate(
    height,
    (y) => List.generate(
      width,
      (x) => List.generate(
        3,
        (channel) =>
            ((imageMatrix[y][x][channel] / 255.0) - mean[channel]) /
            std[channel],
      ),
    ),
  );

  return normalizedMatrix;
}
