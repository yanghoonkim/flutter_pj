import 'package:flutter/material.dart';
import 'package:realtime_object_detection/models/screen_params.dart';

class Recognition {
  String label;
  double score;
  Rect location;

  Recognition(this.label, this.score, this.location);

  Rect get renderLocation {
    final double scaleX = ScreenParams.screenPreviewSize.width / 300;
    final double scaleY = ScreenParams.screenPreviewSize.height / 300;

    return Rect.fromLTWH(location.left * scaleX, location.top * scaleY,
        location.width * scaleX, location.height * scaleY);
  }
}
