import 'package:flutter/material.dart';

import '../theme/figma_quiz_fonts.dart';
import 'figma/figma_scale.dart';

/// 393×852 프레임 퀴즈 화면 하단 CTA.
///
/// 퀴즈_중간 학습창(`293:1662`)과 퀴즈_결과보기창(`131:3552`)이 좌표·색·서체까지
/// 같은 버튼을 쓴다.
class QuizFigmaCtaButton extends StatelessWidget {
  const QuizFigmaCtaButton({
    super.key,
    required this.figma,
    required this.label,
    required this.onTap,
  });

  static const color = Color(0xFF3CC6FF);
  static const horizontalMargin = 24.0;
  static const bottomMargin = 54.0;
  static const height = 50.0;
  static const radius = 13.0;
  static const fontSize = 18.0;

  final FigmaScale figma;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(figma.s(radius));
    return Positioned(
      left: figma.s(horizontalMargin),
      right: figma.s(horizontalMargin),
      bottom: figma.s(bottomMargin),
      height: figma.s(height),
      child: Material(
        color: color,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: FigmaQuizFonts.pretendard,
                fontSize: figma.s(fontSize),
                height: 1.203,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
