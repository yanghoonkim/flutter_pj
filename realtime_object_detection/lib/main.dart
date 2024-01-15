import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realtime_object_detection/models/screen_params.dart';
import 'package:realtime_object_detection/ui/homeview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
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
