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

  /// Figma는 `14`/`day`를 SUIT Thin으로 적어두지만, 정작 그 프레임 렌더는
  /// 굵은 획이다 (SUIT Thin으로 그리면 헤어라인이라 디자인과 전혀 다르다).
  /// 화면 모습을 기준으로 Pretendard Bold를 쓴다. 퀴즈_ox처럼 stroke를 덧입히는
  /// 방식은 이 프레임 CSS에 border가 없어 해당하지 않는다.
  static const streakNumberColor = Color(0xFF00AFF8);
  static const streakLabelColor = Color(0xFF3CC6FF);
  static const streakNumberFontSize = 148.0;
  static const streakDayFontSize = 64.0;
  static const streakSuffixFontSize = 34.0;

  /// `14 day` 묶음의 가로 중심. 프레임 중앙(196.5)에서 살짝 왼쪽이다.
  static const streakBlockCenterX = 192.5;
  static const streakBlockTop = 486.0;

  /// `148 + 간격 + 34`. 자릿수가 많으면 이 안에서 축소된다.
  static const streakBlockHeight = 200.0;
  static const streakDayGap = 4.3;
  static const streakSuffixGap = 14.0;
}
