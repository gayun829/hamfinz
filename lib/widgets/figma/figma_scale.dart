import 'package:flutter/material.dart';

/// Figma 프레임(1237×2629) 좌표를 실제 화면 폭에 맞게 스케일한다.
class FigmaScale {
  const FigmaScale(this.scale);

  static const homeDesignWidth = 1237.0;
  static const homeDesignHeight = 2629.0;
  static const homeContentHeight = 2474.0;

  static const authDesignWidth = 1212.67;
  static const authDesignHeight = 2629.0;

  static const quizDesignWidth = authDesignWidth;
  static const quizDesignHeight = authDesignHeight;
  /// MC 퀴즈 1화면 — [QuizFigmaLayout.contentHeight]와 동기화.
  static const quizContentHeight = 2072.0;

  final double scale;

  double s(double value) => value * scale;

  FigmaScale clamped({double min = 0.8, double max = 1.2}) {
    return FigmaScale(scale.clamp(min, max));
  }

  static FigmaScale ofWidth(double width, {double designWidth = homeDesignWidth}) {
    final safeWidth = width.isFinite && width > 0 ? width : designWidth;
    return FigmaScale(safeWidth / designWidth);
  }

  static FigmaScale ofLayout(
    BoxConstraints constraints, {
    required double designWidth,
    double min = 0.8,
    double max = 1.2,
  }) {
    return ofWidth(
      constraints.maxWidth,
      designWidth: designWidth,
    ).clamped(min: min, max: max);
  }

  /// 가로·세로 모두 들어가도록 더 작은 scale을 사용한다 (스크롤 없이 1화면).
  static FigmaScale ofViewport(
    double width,
    double height, {
    required double designWidth,
    required double designHeight,
  }) {
    if (!height.isFinite || height <= 0) {
      return ofWidth(width, designWidth: designWidth);
    }
    final scaleW = width / designWidth;
    final scaleH = height / designHeight;
    return FigmaScale(scaleW < scaleH ? scaleW : scaleH);
  }

  static FigmaScale ofContext(
    BuildContext context, {
    double designWidth = homeDesignWidth,
  }) {
    return ofWidth(MediaQuery.sizeOf(context).width, designWidth: designWidth);
  }
}

class FigmaBox extends StatelessWidget {
  const FigmaBox({
    super.key,
    required this.figma,
    required this.left,
    required this.top,
    required this.child,
    this.width,
    this.height,
  });

  final FigmaScale figma;
  final double left;
  final double top;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: figma.s(left),
      top: figma.s(top),
      width: width == null ? null : figma.s(width!),
      height: height == null ? null : figma.s(height!),
      child: child,
    );
  }
}

class FigmaCenterBox extends StatelessWidget {
  const FigmaCenterBox({
    super.key,
    required this.figma,
    required this.designWidth,
    required this.top,
    required this.width,
    required this.height,
    required this.child,
    this.centerOffsetX = 0,
  });

  final FigmaScale figma;
  final double designWidth;
  final double top;
  final double width;
  final double height;
  final double centerOffsetX;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final left = (designWidth - width) / 2 + centerOffsetX;
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }
}
