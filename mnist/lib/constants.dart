import 'package:flutter/material.dart';

const double kCanvasSize = 200.0;
const double kStrokeWidth = 12.0;
const bool kIsAntiAlias = true;
const Color kBlackBrushColor = Colors.black;
const int kModelInputSize = 28;
const int kModelOutputSize = 10;
const double kCanvasInnerOffset = 40.0;
const Color kBarColor = Colors.blue;
const Color kBarBackgroundColor = Colors.transparent;
const double kBarWidth = 22;

const Color kBrushBlack = Colors.black;
const Color kBrushWhite = Colors.white;

final Paint drawingPaint = Paint()
  ..strokeCap = StrokeCap.square
  ..isAntiAlias = kIsAntiAlias
  ..color = kBlackBrushColor
  ..strokeWidth = kStrokeWidth;

final Paint kWhitePaint = Paint()
  ..strokeCap = StrokeCap.square
  ..isAntiAlias = kIsAntiAlias
  ..color = kBrushWhite
  ..strokeWidth = kStrokeWidth;

final kBackgroundPaint = Paint()..color = kBrushBlack;

const String kWaitingForInputHeaderString =
    'Please draw a number in the box below';
const String kWaitingForInputFooterString = 'Let me guess...';
const String kGuessingInputString = 'The number you draw is ';
