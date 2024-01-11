import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:realtime_object_detection/models/recognition.dart';
import 'package:realtime_object_detection/service/detection.dart';
import 'package:realtime_object_detection/ui/box_widget.dart';

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
        setState(() {});
      });
    });
  }

  void initCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false)
      ..initialize().then((_) async {
        //await controller!.startImageStream(onLatestImageAvailable);
        setState(() {});
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
      //print('##################################');
      //print(controller!.value.previewSize);
      //print(controller!.value.aspectRatio);
      //print(controller!.value.previewSize!.width);
      //print(MediaQuery.sizeOf(context));
      return Column(
        children: [
          Stack(children: [CameraPreview(controller!)]),
          IconButton(
            onPressed: () async {
              final imagetook = await controller!.takePicture();
              await GallerySaver.saveImage(imagetook.path);
            },
            icon: const Icon(Icons.camera),
            iconSize: 50,
          ),
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
