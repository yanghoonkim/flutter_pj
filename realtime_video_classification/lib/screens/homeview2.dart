import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realtime_video_classification/service/video_classification.dart';
import 'package:image/image.dart' as imglib;
import 'package:realtime_video_classification/constants.dart';

class HomeView2 extends StatelessWidget {
  const HomeView2({super.key});

  @override
  Widget build(BuildContext context) {
    VideoClassification.loadModelLabels().then((_) async {
      VideoClassification.isReady = true;
      await Future.delayed(const Duration(seconds: 1));
      var temp = await VideoClassification.runModelTemp();
    });

    return Scaffold(body: Container());
  }
}
