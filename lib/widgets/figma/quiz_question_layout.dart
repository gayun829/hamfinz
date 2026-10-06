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
    double letterSpacing = 0,
  }) {
    // 테마(M3 bodyMedium)의 자간 0.25가 화면에만 붙으면 잰 높이보다 줄이 늘어난다.
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight,
      letterSpacing: letterSpacing,
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
    double letterSpacing = 0,
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
          letterSpacing: letterSpacing * safeScale,
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

  /// 한 화면에 맞춘 캔버스의 scale로 질문 높이를 잰다. 세로가 모자라 캔버스가
  /// 작아지면 그 scale로 다시 잰다. 비선형 글자 확대는 작은 글씨일수록 더 커져
  /// 줄이 늘 수 있어서, 높이가 더 늘지 않을 때까지 반복한다.
  static double fittedTextHeight({
    required BoxConstraints constraints,
    required double designWidth,
    required double baseCanvasHeight,
    required double minimumHeight,
    required double Function(double scale) measure,
  }) {
    final widthScale = constraints.maxWidth / designWidth;
    var height = measure(widthScale);
    if (!constraints.hasBoundedHeight) return height;
    for (var i = 0; i < 8; i++) {
      final scale = math.min(
        widthScale,
        constraints.maxHeight / (baseCanvasHeight + height - minimumHeight),
      );
      final next = measure(scale);
      if (next <= height) break;
      height = next;
    }
    return height;
  }

  /// 줄 높이의 정확한 배수에서 부동소수점 오차가 1px 올림으로 이어지지 않게 한다.
  static double _ceilDesignPx(double value) {
    const epsilon = 0.01;
    return (value - epsilon).ceilToDouble();
  }
}
