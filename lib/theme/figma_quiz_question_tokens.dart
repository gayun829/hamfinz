import 'package:flutter/material.dart';

/// Figma `137:5521` 퀴즈._객_문제 (393×852) 좌표·색.
abstract final class FigmaQuizQuestionTokens {
  static const background = Color(0xFFFBFBFB);

  static const progressTrack = Color(0xFFE6E6E6);
  static const progressFill = Color(0xFF70D9FF);
  static const progressHighlight = Color(0xFFF4FCFF);
  static const progressHighlightOpacity = 0.36;
  static const questionNumber = Color(0xFF70D9FF);
  static const optionBorder = Color(0xFFD9D9D9);
  static const optionSelectedBorder = Color(0xFF3CC6FF);
  static const optionCorrectFill = Color(0xFFD4F4FF);
  static const optionCorrectBorder = Color(0xFF70D9FF);
  static const optionWrongFill = Color(0xFFFFC4C4);
  static const optionWrongBorder = Color(0xFFFF3C3C);
  static const cta = Color(0xFF3CC6FF);

  static const toggleLeft = 270.0;
  static const toggleTop = 257.0;
  static const toggleWidth = 85.0;
  static const toggleHeight = 32.0;
  static const toggleRadius = 30.815;
  static const toggleBorderWidth = 1.185;
  static const toggleFill = Color(0xFFF5F5F5);
  static const toggleBorder = Color(0xFFD9D9D9);
  static const toggleActive = Color(0xFF00AFF8);
  static const toggleExplainActive = Color(0xFFEE9841);
  static const toggleInactive = Color(0xFF8C8C8C);
  static const explainNumber = Color(0xFFFFCB5A);

  static const explainToggleLeft = 271.0;
  static const explainToggleTop = 359.0;
  static const explainToggleQuestionLeft = 282.72;
  static const explainToggleQuestionTop = 366.0;
  static const explainToggleExplainLeft = 321.48;
  static const explainToggleExplainTop = 366.0;
  static const explainToggleDividerLeft = 313.66;
  static const explainToggleDividerTop = 370.0;

  static const explainBubbleHeight = 223.0;
  static const explainTextLeft = 52.0;
  static const explainTextTop = 166.0;
  static const explainTextWidth = 284.0;
  static const explainTextHeight = 161.0;
  static const toggleFontSize = 14.0;
  static const toggleQuestionLeft = 281.72;
  static const toggleQuestionTop = 264.0;
  static const toggleQuestionWidth = 25.47;
  static const toggleExplainLeft = 320.48;
  static const toggleExplainTop = 264.0;
  static const toggleExplainWidth = 26.63;
  static const toggleLabelHeight = 15.0;
  static const toggleDividerLeft = 312.66;
  static const toggleDividerTop = 268.0;
  static const toggleDividerHeight = 10.0;
  static const toggleDividerWidth = 1.188;

  static const backLeft = 27.0;
  static const backTop = 56.0;
  static const backWidth = 10.644;
  static const backHeight = 21.069;
  static const backTapLeft = 16.0;
  static const backTapTop = 44.0;
  static const backTapSize = 44.0;

  static const progressLeft = 68.0;
  static const progressTop = 59.0;
  static const progressWidth = 291.825;
  static const progressHeight = 16.99;
  static const progressRadius = 8.146;
  static const progressHighlightLeft = 76.544;
  static const progressHighlightTop = 61.94;
  static const progressHighlightHeight = 4.574;
  static const progressHighlightLeftInset =
      progressHighlightLeft - progressLeft;
  static const progressHighlightRightInset = 10.53;

  static const qIconLeft = 35.0;
  static const qIconTop = 108.0;
  static const qIconWidth = 34.001;
  static const qIconHeight = 28.372;

  static const numberLeft = 75.0;
  static const numberTop = 102.0;
  static const numberFontSize = 32.088;
  static const numberWidth = 48.0;
  static const numberHeight = 42.0;

  static const bubbleLeft = 32.0;
  static const bubbleTop = 146.0;
  static const bubbleWidth = 324.0;
  static const bubbleHeight = 118.0;

  static const questionLeft = 52.0;
  static const questionTop = 168.0;
  static const questionWidth = 284.0;
  static const questionHeight = 62.0;
  static const questionFontSize = 22.0;
  static const questionLineHeight = 1.2;

  static const characterLeft = 24.0;
  static const characterTop = 265.213;
  static const characterWidth = 116.377;
  static const characterHeight = 128.787;

  static const characterShadowLeft = 41.0;
  static const characterShadowTop = 378.0;
  static const characterShadowWidth = 81.165;
  static const characterShadowHeight = 25.0;

  static const optionLeft = 24.0;
  static const optionWidth = 345.0;
  static const optionHeight = 64.0;
  static const optionRadius = 13.0;
  static const optionBorderWidth = 1.95;
  static const optionFontSize = 20.0;
  static const optionTops = [417.0, 493.0, 569.0, 645.0];

  static const ctaLeft = 24.0;
  // Figma(748)는 보기와 버튼 사이가 비어 스크롤이 생겨서, 마지막 보기(645) 바로 아래에 붙인다.
  static const ctaGap = 20.0;
  static const ctaTop = 645.0 + optionHeight + ctaGap;
  static const ctaWidth = 345.0;
  static const ctaHeight = 50.0;
  static const ctaRadius = 13.0;
  static const ctaFontSize = 18.0;

  /// 질문이 기본 높이일 때의 캔버스 높이 — 버튼 아래 홈 인디케이터 여백까지.
  static const bottomMargin = 34.0;
  static const contentHeight = ctaTop + ctaHeight + bottomMargin;
}
