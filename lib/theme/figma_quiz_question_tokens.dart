import 'package:flutter/material.dart';

/// Figma 퀴즈._객_문제 (393×852) 좌표·색.
///
/// 짧은 질문은 말풍선+햄핀이(`632:1982`), 긴 질문은 박스(`632:1090`),
/// 정답은 `632:1288`·`632:1182`, 해설은 `632:1795`.
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

  // 문제/해설 토글. 위치는 레이아웃마다 다르고 안쪽 배치는 같다.
  static const toggleWidth = 85.0;
  static const toggleHeight = 32.0;
  static const toggleRadius = 30.815;
  static const toggleBorderWidth = 1.185;
  static const toggleFill = Color(0xFFF5F5F5);
  static const toggleBorder = Color(0xFFD9D9D9);
  static const toggleActive = Color(0xFF00AFF8);
  static const toggleExplainActive = Color(0xFFEE9841);
  static const toggleInactive = Color(0xFF8C8C8C);
  static const toggleFontSize = 14.0;
  static const toggleQuestionDx = 11.72;
  static const toggleQuestionWidth = 25.47;
  static const toggleExplainDx = 50.48;
  static const toggleExplainWidth = 26.63;
  static const toggleLabelDy = 7.0;
  static const toggleLabelHeight = 15.0;
  static const toggleDividerDx = 42.66;
  static const toggleDividerDy = 11.0;
  static const toggleDividerHeight = 10.0;
  static const toggleDividerWidth = 1.188;
  static const bubbleToggle = Offset(270, 257);
  static const boxToggle = Offset(270, 368);
  static const explainToggle = Offset(272, 368);

  static const explainNumber = Color(0xFFFFCB5A);

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

  static const questionLineHeight = 1.2;

  // 짧은 질문 — 꼬리 달린 말풍선. 60자 이하이면서 세 줄에 들어갈 때만 쓴다.
  static const shortQuestionMaxLength = 60;
  static const bubbleLeft = 32.0;
  static const bubbleTop = 159.0;
  static const bubbleWidth = 324.0;
  static const bubbleHeight = 107.0;

  /// 꼬리를 뺀 본체(159~247). 글은 두 줄이든 세 줄이든 이 안 세로 가운데에 둔다.
  static const bubbleBodyHeight = 88.0;
  static const bubbleTextLeft = 51.0;
  static const bubbleTextWidth = 287.0;
  static const bubbleTextMaxLines = 3;
  static const bubbleFontSize = 18.0;
  static const bubbleLetterSpacing = 0.54;

  // 긴 질문·해설 — 꼬리 없는 박스. 글이 넘치면 박스가 아래로 늘어난다.
  static const boxLeft = 34.0;
  static const boxTop = 159.0;
  static const boxWidth = 324.0;
  static const boxHeight = 183.0;

  /// 정답·해설 화면은 토글 자리까지 박스가 조금 더 길다.
  static const boxAnswerHeight = 199.0;
  static const boxTextLeft = 49.0;
  static const boxTextTop = 175.0;
  static const boxTextWidth = 294.0;
  static const boxTextHeight = 147.0;

  /// 61자 이상이면 20에서 18로 줄인다.
  static const longQuestionMinLength = 61;
  static const boxFontSize = 20.0;
  static const longQuestionFontSize = 18.0;
  static const explainFontSize = 18.0;

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
