import 'package:flutter/material.dart';
import 'package:mnist/recognizer_screen.dart';

void main() => runApp(const MnistApp());

class MnistApp extends StatelessWidget {
  const MnistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Number Recognizer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const RecognizerScreen(title: 'Number Recognizer'));
  }
}
