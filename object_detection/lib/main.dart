import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wakelock/wakelock.dart';
import 'package:object_detection/detection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Object Detection',
      home: ObjectDetectionScreen(),
    );
  }
}

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  Uint8List? _image;
  final picker = ImagePicker();
  ObjectDetection? objectDetection;

  @override
  void initState() {
    objectDetection = ObjectDetection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Object Detection'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                child: _image != null
                    ? Image.memory(_image!)
                    : const Text(
                        'No Image selected',
                        style: TextStyle(fontSize: 22),
                      ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async {
                    var imageXfile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (imageXfile != null) {
                      _image = await objectDetection!.detect(imageXfile.path);
                    }

                    setState(() {});
                  },
                  icon: const Icon(Icons.image),
                  iconSize: 50,
                ),
                IconButton(
                  onPressed: () async {
                    var imageXfile =
                        await picker.pickImage(source: ImageSource.camera);
                    if (imageXfile != null) {
                      _image = await objectDetection!.detect(imageXfile.path);
                    }

                    setState(() {});
                  },
                  icon: const Icon(Icons.camera),
                  iconSize: 50,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
