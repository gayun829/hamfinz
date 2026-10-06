import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'figma_scale.dart';

/// 퀴즈 코인 장식의 금빛 막대 (Figma Rectangle 808/810 등).
///
/// [box]는 회전 후 바운딩 박스, [size]는 회전 전 막대 크기(디자인 px)다.
class QuizCoinBar extends StatelessWidget {
  const QuizCoinBar({
    super.key,
    required this.figma,
    required this.box,
    required this.size,
    required this.degrees,
    required this.radius,
    required this.opacity,
    required this.glowOffsetY,
    required this.glowBlur,
    required this.glowSpread,
  });

  static const _top = Color(0xFFFFCA54);
  static const _bottom = Color(0xFFFFB741);
  static const _glow = Color.fromRGBO(255, 255, 89, 0.25);

  final FigmaScale figma;
  final Rect box;
  final Size size;
  final double degrees;
  final double radius;
  final double opacity;
  final double glowOffsetY;
  final double glowBlur;
  final double glowSpread;

  @override
  Widget build(BuildContext context) {
    return FigmaBox(
      figma: figma,
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      child: Center(
        child: Transform.rotate(
          angle: degrees * math.pi / 180,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: figma.s(size.width),
              height: figma.s(size.height),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(figma.s(radius)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_top, _bottom],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _glow,
                    offset: Offset(0, figma.s(glowOffsetY)),
                    blurRadius: figma.s(glowBlur),
                    spreadRadius: figma.s(glowSpread),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
