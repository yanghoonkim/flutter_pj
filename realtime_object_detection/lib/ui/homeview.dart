import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:realtime_object_detection/service/detection.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late List<CameraDescription> cameras;
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    initCamera();
    RootIsolate.start();
  }

  void initCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false)
      ..initialize().then((_) async {
        await controller!.startImageStream(onLatestImageAvailable);
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
      return CameraPreview(controller!);
    }
  }
}

void onLatestImageAvailable(CameraImage cameraImage) {
  RootIsolate.processFrame(cameraImage);
}
