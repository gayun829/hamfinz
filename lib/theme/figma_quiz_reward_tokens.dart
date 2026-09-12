import 'package:flutter/material.dart';

/// Figma node `131:3546` 퀴즈_결과보기창 (393×852) Dev Mode 토큰.
abstract final class FigmaQuizRewardTokens {
  static const designWidth = 393.0;
  static const designHeight = 852.0;

  static const background = Color(0xFFFBFBFB);

  static const titleColor = Color(0xFF00AFF8);
  static const titleFontSize = 42.0;
  static const titleLetterSpacing = 2.1;
  static const titleTop = 435.0;

  /// Figma 박스는 `left 107 / w 180`이라 중심이 프레임 중앙과 사실상 같다.
  /// 대체 서체가 더 넓어 줄바꿈이 나므로 폭을 묶지 않고 가운데 정렬한다.
  static const titleCenterX = 197.0;

  static const hamster = Rect.fromLTWH(96.01, 198, 193.384, 216);
  static const hamsterShadow = Rect.fromLTWH(132.99, 385.02, 119.785, 36.8951);

  /// 33×33 박스 + 11.4% 인셋.
  static const sparkleBox = 33.0;
  static const sparkleInner = 25.4738;
  static const sparkleLeftTop = Offset(61, 318);
  static const sparkleRightTop = Offset(304, 446);

  /// 세 보상 수치는 Inter SemiBold였지만 번들된 Pretendard로 대체한다.
  static const statFontSize = 14.024;
  static const statLineHeight = 17.53 / 14.024;

  static const statCorrectIcon = Rect.fromLTWH(53, 544, 34.0473, 39.9972);
  static const statCorrectTextLeft = 87.59;
  static const statCorrectTextTop = 562.37;
  static const statCorrectColor = Color(0xFFFB8B3B);

  static const statSeedIcon = Rect.fromLTWH(163.02, 552.01, 29.6363, 28.709);
  static const statSeedTextLeft = 200.46;
  static const statSeedTextTop = 560.75;
  static const statSeedColor = Color(0xFFFFCA55);

  static const statEnergyIcon = Rect.fromLTWH(271.01, 553.97, 35.6237, 24.8838);
  static const statEnergyTextLeft = 315.97;
  static const statEnergyTextTop = 559.84;
  static const statEnergyColor = Color(0xFFFBB03B);
}
