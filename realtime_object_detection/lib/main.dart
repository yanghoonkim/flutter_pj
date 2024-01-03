import 'package:flutter/material.dart';
import 'package:realtime_object_detection/ui/homeview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime Object Detection',
      home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.orange,
            title: const Text(
              'Realtime Object Detection',
            ),
          ),
          body: const HomeView()),
    );
  }
}
