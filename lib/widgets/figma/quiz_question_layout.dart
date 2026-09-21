import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Figma의 고정 좌표를 유지하면서 질문 문장에 필요한 세로 공간을 계산한다.
abstract final class QuizQuestionLayout {
  static TextStyle textStyle({
    required String fontFamily,
    required double fontSize,
    required double lineHeight,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.black,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight,
      color: color,
    );
  }

  static double textHeight({
    required String text,
    required double width,
    required double fontSize,
    required double lineHeight,
    required double minimumHeight,
    required String fontFamily,
    FontWeight fontWeight = FontWeight.w400,
    TextAlign textAlign = TextAlign.center,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final style = textStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      lineHeight: lineHeight,
      fontWeight: fontWeight,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: math.max(0, width - 2));

    final metricsHeight = painter.computeLineMetrics().fold<double>(
      0,
      (sum, line) => sum + line.height,
    );
    final measured = math.max(painter.height, metricsHeight);
    return math.max(minimumHeight, measured.ceilToDouble());
  }
}
