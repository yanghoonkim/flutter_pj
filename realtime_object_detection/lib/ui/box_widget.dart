import 'package:flutter/material.dart';
import 'package:realtime_object_detection/models/recognition.dart';

class BoxWidget extends StatelessWidget {
  Recognition result;
  BoxWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.primaries[
        (Colors.primaries.length + result.label.codeUnitAt(0)) %
            Colors.primaries.length];

    return Positioned.fromRect(
        rect: result.renderLocation,
        child: Container(
            width: result.renderLocation.width,
            height: result.renderLocation.height,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 3),
            ),
            child: Align(
                alignment: Alignment.topLeft,
                child: FittedBox(
                    child: Container(
                        color: color,
                        child: Row(
                          children: [
                            Text(result.label),
                            const Text(' '),
                            Text(result.score.toStringAsFixed(2))
                          ],
                        ))))));
  }
}
