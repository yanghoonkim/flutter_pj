import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realtime_object_detection/models/recognition.dart';
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

  List? results;

  @override
  void initState() {
    super.initState();
    initCamera();
    RootIsolate.start().then((_) {
      subscription = RootIsolate.resultStream.stream.listen((values) {
        results = values;
        //print(results![1]);
        //print(results!.length);
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
          Stack(children: [CameraPreview(controller!)]),
          IconButton(
            onPressed: () async {
              Directory appDocDir = await getApplicationDocumentsDirectory();
              //final imagetook = await controller!.takePicture();
              final imagetook = results![1];
              // Create a temporary file
              String tempFilePath =
                  '${appDocDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
              File tempFile = File(tempFilePath);

              // Write the image to the temporary file
              tempFile.writeAsBytesSync(image_lib.encodePng(imagetook));

              // Return XFile from the temporary file path
              final imagetook_ = XFile(tempFile.path);

              await GallerySaver.saveImage(imagetook_.path);
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
