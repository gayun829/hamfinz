import 'package:flutter/material.dart';

/// Figma node `293:1649` 퀴즈_중간 학습창 (393×852) Dev Mode 토큰.
abstract final class FigmaQuizStreakTokens {
  static const designWidth = 393.0;
  static const designHeight = 852.0;

  static const background = Color(0xFFFBFBFB);

  /// 뒤쪽 햇살 광선. 흐린 쪽(42%)과 진한 쪽 두 종류다.
  static const rayMint = Color(0xFFB7F0F2);
  static const rayMintOpacity = 0.42;
  static const raySky = Color(0xFFBFEEFF);
  static const raySize = Size(34.185, 174.461);
  static const rayRadius = 87.524;

  /// `14`/`day`는 SUIT Thin에 바깥쪽 외곽선(6 / 2.61)을 두른 글자다. 내보낸 CSS에는
  /// 외곽선이 안 나오니 Plugin API의 `strokes`로 확인해야 한다.
  /// Figma 바깥쪽 N px = Flutter 가운데 정렬 stroke 2N px.
  static const streakNumberColor = Color(0xFF00AFF8);
  static const streakLabelColor = Color(0xFF3CC6FF);
  static const streakNumberFontSize = 148.0;
  static const streakNumberStroke = 12.0;
  static const streakDayFontSize = 64.0;
  static const streakDayStroke = 5.22;
  static const streakSuffixFontSize = 34.0;

  /// `14 day` 묶음의 가로 중심. 프레임 중앙(196.5)에서 살짝 왼쪽이다.
  static const streakBlockCenterX = 191.0;

  /// 글자 줄 높이를 1로 줄인 묶음의 위쪽. 숫자 글자 모양이 Figma 위치에 오는 값이다.
  static const streakBlockTop = 501.0;

  /// `148 + 34`. 자릿수가 많으면 이 안에서 축소된다.
  static const streakBlockHeight = 200.0;
  static const streakDayGap = 7.5;

  /// `day`는 숫자 기준선보다 조금 위에 놓인다.
  static const streakDayLift = 9.0;
  static const streakSuffixGap = 2.0;

  /// `streak!`의 오른쪽 끝은 `day`보다 3 안쪽이다.
  static const streakSuffixRightInset = 3.0;
}
