import 'package:flutter/material.dart';

class ClosetStage extends StatelessWidget {
  const ClosetStage({super.key, required this.avatar, required this.height});
  final Widget avatar;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = height / 280;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/figma/shop/gibonbaegyoung.png',
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              top: 175 * scale,
              width: 210 * scale,
              height: 128 * scale,
              child: Transform.translate(
                offset: Offset(13 * scale, 0),
                child: Image.asset(
                  'assets/figma/shop/tongnamu.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 28 * scale,
              width: 200 * scale,
              height: 200 * scale,
              child: avatar,
            ),
          ],
        ),
      ),
    );
  }
}
