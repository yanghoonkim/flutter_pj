import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realtime_object_detection/models/recognition.dart';
import 'package:realtime_object_detection/models/screen_params.dart';
import 'package:realtime_object_detection/service/detection.dart';
import 'package:realtime_object_detection/ui/box_widget.dart';
import 'package:image/image.dart' as image_lib;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late List<CameraDescription> cameras;
  CameraController? controller;

  StreamSubscription? subscription;

  List<Recognition>? results;

  @override
  void initState() {
    super.initState();
    initCamera();
    RootIsolate.start().then((_) {
      subscription = RootIsolate.resultStream.stream.listen((values) {
        results = values;
        //if (results!.isNotEmpty) {
        //  print(results![0].label);
        //}
        setState(() {});
      });
    });
  }

  void initCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false)
      ..initialize().then((_) async {
        await controller!.startImageStream(onLatestImageAvailable);
        setState(() {});
        ScreenParams.previewSize = controller!.value.previewSize!;
      });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(
          child: SizedBox(
        width: 150,
        height: 150,
        child: CircularProgressIndicator(
          backgroundColor: Colors.orange,
          color: Colors.yellow,
          strokeWidth: 15,
        ),
      ));
    } else {
      return Column(
        children: [
          Stack(children: [
            CameraPreview(controller!),
            AspectRatio(
                aspectRatio: 1 / controller!.value.aspectRatio,
                child: boundingBoxes())
          ]),
        ],
      );
    }
  }

  void onLatestImageAvailable(CameraImage cameraImage) {
    RootIsolate.processFrame(cameraImage);
  }

  Widget boundingBoxes() {
    if (results == null) {
      return const SizedBox.shrink();
    } else {
      return Stack(
          children: results!.map((box) => BoxWidget(result: box)).toList());
    }
  }
}
