import 'dart:async';
import 'dart:collection';

import 'package:camera/camera.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
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
  CircularBuffer<imglib.Image> images = CircularBuffer<imglib.Image>(15);
  late Timer _timer;

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    controller = CameraController(_cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    controller!.initialize().then((_) {
      controller!.startImageStream(onLatestImageAvailable);
      _timer = Timer.periodic(const Duration(milliseconds: 333), (Timer timer) {
        processFrame(currentCameraImage);
      });

      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();

    var buffer = CircularBuffer(3);
    buffer.add(1);
    buffer.add(2);
    buffer.add(3);
    buffer.add(4);
    print(buffer);

    _initCamera();
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
          : CameraPreview(controller!),
    );
  }

  void onLatestImageAvailable(CameraImage cameraImage) {
    currentCameraImage = cameraImage;
    //print(images.length);
  }

  void processFrame(CameraImage? currentCameraImage) {
    if (currentCameraImage != null) {
      ImageUtils.convertCameraImage(currentCameraImage).then((image) {
        images.add(image!);
      });
    }
  }
}
