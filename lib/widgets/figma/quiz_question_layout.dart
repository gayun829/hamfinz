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
    double scale = 1,
  }) {
    final safeScale = scale.isFinite && scale > 0 ? scale : 1.0;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle(
          fontFamily: fontFamily,
          fontSize: fontSize * safeScale,
          lineHeight: lineHeight,
          fontWeight: fontWeight,
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );
    try {
      painter.layout(maxWidth: math.max(0, (width - 2) * safeScale));
      final designHeight = painter.height / safeScale;
      return math.max(minimumHeight, _ceilDesignPx(designHeight));
    } finally {
      painter.dispose();
    }
  }

  /// 줄 높이의 정확한 배수에서 부동소수점 오차가 1px 올림으로 이어지지 않게 한다.
  static double _ceilDesignPx(double value) {
    const epsilon = 0.01;
    return (value - epsilon).ceilToDouble();
  }
}
