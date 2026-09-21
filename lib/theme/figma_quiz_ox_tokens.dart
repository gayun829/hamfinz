import 'package:flutter/material.dart';

/// Figma `137:5890` 퀴즈_ox / `137:5957` 정답 / `291:971` 해설 (393×852).
abstract final class FigmaQuizOxTokens {
  static const background = Color(0xFFFBFBFB);

  // 진행바 `137:5897` — 4지선다 화면과 동일한 좌표.
  static const progressTrack = Color(0xFFE6E6E6);
  static const progressFill = Color(0xFF70D9FF);
  static const progressHighlight = Color(0xFFF4FCFF);
  static const progressHighlightOpacity = 0.36;
  static const progressLeft = 68.0;
  static const progressTop = 59.0;
  static const progressWidth = 291.825;
  static const progressHeight = 16.99;
  static const progressRadius = 8.146;
  static const progressHighlightLeft = 76.544;
  static const progressHighlightTop = 61.939;
  static const progressHighlightHeight = 4.574;
  static const progressHighlightLeftInset =
      progressHighlightLeft - progressLeft;
  static const progressHighlightRightInset = 10.53;

  // 뒤로가기 `137:5901` — outer 6.602×13.068에 stroke overflow(-24.12%/-12.13%).
  static const backLeft = 25.407;
  static const backTop = 59.376;
  static const backWidth = 9.786;
  static const backHeight = 16.238;
  static const backTapLeft = 16.0;
  static const backTapTop = 45.5;
  static const backTapSize = 44.0;

  /// 캐릭터 `161:2428` Group 396 — ox2 프레임에서 가져온 에셋.
  static const characterLeft = 116.0;
  static const characterTop = 121.687;
  static const characterWidth = 161.0;
  static const characterHeight = 177.311;

  /// 해설 캐릭터 `291:997` Group 194.
  static const explainCharacterLeft = 117.0;
  static const explainCharacterTop = 122.0;
  static const explainCharacterWidth = 159.445;
  static const explainCharacterHeight = 175.596;

  /// 발밑 그림자 `137:5891` Group 110.
  static const characterShadowLeft = 140.0;
  static const characterShadowTop = 278.692;
  static const characterShadowWidth = 113.0;
  static const characterShadowHeight = 34.806;

  // 문제 번호 `137:5944` + Q 아이콘 `137:5945`.
  static const qIconLeft = 41.0;
  static const qIconTop = 323.0;
  static const qIconWidth = 34.001;
  static const qIconHeight = 28.372;
  static const numberLeft = 79.0;
  static const numberTop = 317.0;
  static const numberWidth = 60.0;
  static const numberHeight = 42.0;
  static const numberFontSize = 31.0;
  static const numberLineHeight = 39 / 31;

  /// SUIT Thin 위에 얹히는 텍스트 stroke (`border: 1.5px solid #70D9FF`).
  static const numberStrokeWidth = 1.5;
  static const number = Color(0xFF70D9FF);
  static const explainNumber = Color(0xFFFFCB5A);

  // 문제 카드 `137:5904` + 헤더 `137:5905`.
  static const cardLeft = 34.0;
  static const cardTop = 363.0;
  static const cardWidth = 324.0;
  static const cardHeight = 316.0;
  static const cardRadius = 26.0;
  static const cardBorderWidth = 2.0;
  static const cardBorder = Color(0xFFC4EDFD);
  static const headerHeight = 115.0;
  static const headerFill = Color(0xFFD9FAFF);
  static const explainCardBorder = Color(0xFFF9E08D);
  static const explainHeaderFill = Color(0xFFFFF8D3);

  /// 질문 `137:5906` — 짧은 문장은 Figma의 중심을 유지하고, 긴 문장은
  /// 이 최소 높이에서 아래로 확장하며 카드·선택지·CTA를 함께 밀어낸다.
  static const questionLeft = 54.0;
  static const questionWidth = 284.0;
  static const questionFontSize = 22.0;
  static const questionLineHeight = 26 / 22;
  static const questionHeight = 78.0;
  static const questionTop = 381.5;

  // O/X 선택지 `137:5907` Group 284.
  static const optionTop = 510.0;
  static const optionWidth = 135.0;
  static const optionHeight = 145.0;
  static const optionRadius = 13.0;
  static const optionBorderWidth = 1.0;
  static const optionSelectedBorderWidth = 2.0;
  static const optionBorder = Color(0xFFBBBBBB);
  static const optionLefts = [55.0, 202.0];

  /// O `137:5911`(76×76 @84,545) / X `137:5909`(69×69 @235,548)에 stroke overflow 반영.
  static const markLefts = [80.0, 233.0];
  static const markTops = [541.0, 546.0];
  static const markSizes = [84.0, 73.0];
  static const mark = Color(0xFFCECECE);

  // 선택 중 / 정답 `137:5969`·`137:5970`.
  static const optionSelectedBorder = Color(0xFF3CC6FF);
  static const optionCorrectFill = Color(0xFFD4F4FF);
  static const optionCorrectBorder = Color(0xFF70D9FF);
  static const optionWrongFill = Color.fromRGBO(255, 60, 60, 0.3);
  static const optionWrongBorder = Color(0xFFFF3C3C);
  static const optionAnswerBorderWidth = 1.95;

  // 해설문 `291:984`.
  static const explainTextLeft = 54.0;
  static const explainTextTop = 510.0;
  static const explainTextWidth = 284.0;
  static const explainTextHeight = 149.0;
  static const explainTextFontSize = 20.0;

  // 문제/해설 토글 `137:5975` / `291:985`.
  static const toggleLeft = 250.0;
  static const toggleTop = 462.0;
  static const toggleWidth = 85.0;
  static const toggleHeight = 32.0;
  static const toggleRadius = 30.815;
  static const toggleBorderWidth = 1.185;
  static const toggleFill = Colors.white;
  static const toggleBorder = Color(0xFFD9D9D9);
  static const toggleActive = Color(0xFF00AFF8);
  static const toggleExplainActive = Color(0xFFEE9841);
  static const toggleInactive = Color(0xFF8C8C8C);
  static const toggleFontSize = 14.0;
  static const toggleQuestionLeft = 261.72;
  static const toggleQuestionTop = 469.0;
  static const toggleQuestionWidth = 25.475;
  static const toggleExplainLeft = 300.48;
  static const toggleExplainTop = 469.0;
  static const toggleExplainWidth = 26.633;
  static const toggleLabelHeight = 15.0;
  static const toggleDividerLeft = 292.66;
  static const toggleDividerTop = 473.0;
  static const toggleDividerWidth = 1.185;
  static const toggleDividerHeight = 10.0;

  // CTA `137:5895` + 라벨 `137:5896`.
  static const ctaLeft = 24.0;
  static const ctaTop = 748.0;
  static const ctaWidth = 345.0;
  static const ctaHeight = 50.0;
  static const ctaRadius = 13.0;
  static const ctaFontSize = 18.0;
  static const cta = Color(0xFF3CC6FF);
}
