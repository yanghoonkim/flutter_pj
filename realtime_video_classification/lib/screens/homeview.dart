import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:realtime_video_classification/constants.dart';
import 'package:realtime_video_classification/service/video_classification.dart';
import 'package:realtime_video_classification/utils/image_utils.dart';
import 'package:image/image.dart' as imglib;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late List<CameraDescription> _cameras;
  CameraController? controller;
  CameraImage? currentCameraImage;
  CircularBuffer<List<List<List<double>>>> images =
      CircularBuffer<List<List<List<double>>>>(bufferSize);
  late Timer _timer;

  static double? actionProbs;
  static String? action;

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    controller = CameraController(_cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    controller!.initialize().then((_) {
      controller!.startImageStream(onLatestImageAvailable);
      int ms = (1000 / imgFps).round();
      _timer = Timer.periodic(Duration(milliseconds: ms), (Timer timer) {
        processFrame(currentCameraImage);
      });

      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
    VideoClassification.loadModelLabels().then((_) {
      VideoClassification.isReady = true;
      final temp = VideoClassification.inputTensors.map((e) => e.name);
      for (var element in temp) {
        print(element);
      }
      print(VideoClassification.inputTensors);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const Image(
            image: AssetImage('assets/appbar.png'), fit: BoxFit.cover),
      ),
      body: controller == null
          ? LoadingIndicator(
              indicatorType: Indicator.circleStrokeSpin,
              colors: [Colors.purple[900]!],
              strokeWidth: 3,
            )
          : Column(
              children: [
                CameraPreview(controller!),
                Center(
                  child: Text(
                    '$action: $actionProbs',
                    style: const TextStyle(color: Colors.black, fontSize: 30),
                  ),
                )
              ],
            ),
    );
  }

  void onLatestImageAvailable(CameraImage cameraImage) {
    currentCameraImage = cameraImage;
  }

  void processFrame(CameraImage? currentCameraImage) async {
    if (currentCameraImage != null) {
      ImageUtils.convertCameraImage(currentCameraImage).then((image) {
        if (Platform.isAndroid) {
          // 일단 알아야 할 정보는 ios 든 android든 controller.previewSize는 모두 landscape
          // 하지만 imageStream의 경우 ios는 자동으로 portrait로 바꿔주는 반면 android는 그렇지 않다
          image = imglib.copyRotate(image!, angle: 90);
        }

        imglib.Image resizedImage = imglib.copyResize(image!,
            width: mlModelInputSize, height: mlModelInputSize);

        // Creating normalized matrix representation, [172, 172, 3]
        final imageMatrix = List.generate(
          resizedImage.height,
          (y) => List.generate(
            resizedImage.width,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            },
          ),
        );

        images.add(imageMatrix);
      });
      if (VideoClassification.isReady & (images.length == bufferSize)) {
        await VideoClassification.runModel(images).then((value) {
          VideoClassification.isReady = true;
          actionProbs = value.$1;
          action = value.$2;
          setState(() {});
        });
        //VideoClassification.runModelTemp();
      }
    }
  }
}
