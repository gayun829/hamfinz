import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'figma_scale.dart';

/// Figma 캔버스가 viewport에 맞추는 방식.
enum FigmaCanvasFit {
  /// [designWidth] 기준 균일 스케일. Figma 비율 유지, 세로 overflow 시 스크롤.
  widthScroll,

  /// min(가로, 세로) scale로 한 화면에 맞춤. 좌우/상하 여백 가능.
  viewport,

  /// 가로 폭 scale, 스크롤·viewport 정렬 없음.
  width,
}

/// Figma 프레임을 폭 기준 균일 스케일로 그대로 렌더링한다.
class FigmaCanvas extends StatelessWidget {
  const FigmaCanvas({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.builder,
    this.backgroundColor = Colors.white,
    this.scrollable = true,
    this.fit = FigmaCanvasFit.width,
    this.fillWidth = false,
    this.clipContent = true,
  });

  final double designWidth;
  final double designHeight;
  final Color backgroundColor;
  final bool scrollable;
  final FigmaCanvasFit fit;

  /// [FigmaCanvasFit.viewport]일 때 가로를 viewport에 맞추고 세로는 잘린다.
  final bool fillWidth;

  /// false면 맵 등 프레임 밖으로 나가는 요소를 잘리지 않는다.
  final bool clipContent;
  final List<Widget> Function(BuildContext context, FigmaScale figma) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final hasBoundedHeight = maxHeight.isFinite && maxHeight > 0;

        final figma = switch (fit) {
          FigmaCanvasFit.viewport when hasBoundedHeight && !fillWidth =>
            FigmaScale.ofViewport(
              constraints.maxWidth,
              maxHeight,
              designWidth: designWidth,
              designHeight: designHeight,
            ),
          FigmaCanvasFit.viewport ||
          FigmaCanvasFit.widthScroll ||
          FigmaCanvasFit.width =>
            FigmaScale.ofWidth(
              constraints.maxWidth,
              designWidth: designWidth,
            ),
        };

        final contentWidth = fillWidth && fit == FigmaCanvasFit.viewport
            ? constraints.maxWidth
            : figma.s(designWidth);
        final contentHeight = figma.s(designHeight);
        final fitsInViewport = hasBoundedHeight &&
            contentHeight <= maxHeight + 0.5;

        final frame = SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: ColoredBox(
            color: backgroundColor,
            child: Stack(
              clipBehavior: clipContent ? Clip.hardEdge : Clip.none,
              children: builder(context, figma),
            ),
          ),
        );

        final alignWhenFits = fit == FigmaCanvasFit.widthScroll ||
                fit == FigmaCanvasFit.viewport
            ? Alignment.bottomCenter
            : Alignment.topCenter;

        final alignedFrame = Align(
          alignment: fitsInViewport ? alignWhenFits : Alignment.topCenter,
          child: frame,
        );

        if (fit == FigmaCanvasFit.width && !scrollable) {
          return SizedBox(
            width: constraints.maxWidth,
            height: contentHeight,
            child: alignedFrame,
          );
        }

        if (fit == FigmaCanvasFit.viewport && !scrollable && hasBoundedHeight) {
          return SizedBox(
            width: constraints.maxWidth,
            height: maxHeight,
            child: alignedFrame,
          );
        }

        if (!scrollable) {
          return SizedBox(
            width: constraints.maxWidth,
            height: hasBoundedHeight ? maxHeight : contentHeight,
            child: alignedFrame,
          );
        }

        final scrollMinHeight = hasBoundedHeight
            ? (fitsInViewport ? maxHeight : contentHeight)
            : contentHeight;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: scrollMinHeight,
              minWidth: constraints.maxWidth,
            ),
            child: alignedFrame,
          ),
        );
      },
    );
  }
}

/// Figma export의 overflow-hidden + width 202.61% 크롭 패턴.
///
/// Figma MCP가 내보내는 `w-[202.61%]` 이미지는 가로로 2장이 붙은 PNG에서
/// 왼쪽 캐릭터만 보이도록 잘라 쓰는 방식이다. OverflowBox 대신 ClipRect + Image.width를 쓴다.
class FigmaCroppedAsset extends StatelessWidget {
  const FigmaCroppedAsset({
    super.key,
    required this.figma,
    required this.top,
    required this.width,
    required this.height,
    required this.asset,
    this.left,
    this.centerOffsetX = 0,
    this.designWidth = FigmaScale.homeDesignWidth,
    this.imageWidthFactor = 2.0261,
    this.imageOffsetXFactor = 0,
  });

  final FigmaScale figma;
  final double? left;
  final double top;
  final double width;
  final double height;
  final String asset;
  final double centerOffsetX;
  final double designWidth;
  final double imageWidthFactor;
  final double imageOffsetXFactor;

  @override
  Widget build(BuildContext context) {
    final boxLeft = left ?? (designWidth - width) / 2 + centerOffsetX;
    return FigmaBox(
      figma: figma,
      left: boxLeft,
      top: top,
      width: width,
      height: height,
      child: ClipRect(
        child: SizedBox(
          width: figma.s(width),
          height: figma.s(height),
          child: Transform.translate(
            offset: Offset(figma.s(width * imageOffsetXFactor), 0),
            child: Image.asset(
              asset,
              width: figma.s(width * imageWidthFactor),
              height: figma.s(height),
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma `inset-[-5.09%]` + Gaussian blur glow. flutter_svg는 filter 미지원.
class FigmaAuthHeroGlow extends StatelessWidget {
  const FigmaAuthHeroGlow({
    super.key,
    required this.figma,
    required this.left,
    required this.top,
    required this.size,
  });

  final FigmaScale figma;
  final double left;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    final insetScale = 1.0509;
    final circleSize = figma.s(size * 0.91 * insetScale);
    final blur = figma.s(11.8);

    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: size,
      height: size,
      child: OverflowBox(
        maxWidth: circleSize,
        maxHeight: circleSize,
        child: Transform.flip(
          flipY: true,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              width: circleSize,
              height: circleSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x6167D3FA),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FigmaPill extends StatelessWidget {
  const FigmaPill({
    super.key,
    required this.figma,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    this.radius,
  });

  final FigmaScale figma;
  final double left;
  final double top;
  final double width;
  final double height;
  final Color color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? height / 2;
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(figma.s(r)),
        ),
      ),
    );
  }
}

class FigmaTapArea extends StatelessWidget {
  const FigmaTapArea({
    super.key,
    required this.figma,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.child,
    this.onTap,
  });

  final FigmaScale figma;
  final double left;
  final double top;
  final double width;
  final double height;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}

class FigmaLabel extends StatelessWidget {
  const FigmaLabel({
    super.key,
    required this.figma,
    required this.left,
    required this.top,
    required this.text,
    required this.fontSize,
    this.color = Colors.black,
    this.fontWeight = FontWeight.w400,
    this.width,
  });

  final FigmaScale figma;
  final double left;
  final double top;
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: figma.s(fontSize),
          fontWeight: fontWeight,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}
