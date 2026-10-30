import 'package:flutter/material.dart';

/// 얇은 Thin 숫자에 디자인의 텍스트 stroke(외곽선)를 덧입힌다.
/// 같은 글자를 stroke로 한 번, fill로 한 번 겹쳐 그린다.
class StrokedText extends StatelessWidget {
  const StrokedText(
    this.text, {
    super.key,
    required this.style,
    required this.color,
    required this.strokeWidth,
  });

  final String text;
  final TextStyle style;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 스크린리더가 숫자를 두 번 읽지 않도록 외곽선 층은 의미에서 뺀다.
        ExcludeSemantics(
          child: Text(
            text,
            style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round
              ..color = color,
            ),
          ),
        ),
        Text(text, style: style.copyWith(color: color)),
      ],
    );
  }
}
