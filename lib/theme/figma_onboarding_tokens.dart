import 'package:flutter/material.dart';

/// Figma `👀 9.6 화면작업중` — 온보딩 (393×852).
///
/// | 화면 | node |
/// |------|------|
/// | 로고+햄핀 등장창 | `478:1213` |
/// | 맨처음 설치 시 초기 화면 | `102:12145` |
/// | 다른 방법 로그인_닉네임 | `439:419` |
/// | 다른 방법 로그인_이메일 | `439:463` |
/// | 다른 방법 로그인_비밀번호 | `439:700` |
/// | 다른 방법 로그인_인증번호 | `439:644` |
/// | 다른 방법 로그인_약관 | `439:2779` |
///
/// 입력 화면 4개는 좌표가 같다 — 말풍선·햄스터·라벨·밑줄 위치를 공유하고
/// 밑줄 아래 보조 영역(도움말·재전송·규칙)만 화면마다 다르다.
abstract final class FigmaOnboardingTokens {
  static const designWidth = 393.0;

  // Colors
  static const background = Color(0xFFFBFBFB);
  static const accent = Color(0xFF3CC6FF); // CTA·라벨·밑줄·체크
  static const bubbleFill = Color(0xFFCAF3FF);
  static const splashBackground = Color(0xFFCAF3FF);
  static const placeholder = Color(0xFFBBBBBB);
  static const timer = Color(0xFFFF3C3C);
  static const kakaoFill = Color(0xFFFFE300);
  static const clearCircle = Color(0xFFBABDCC);
  static const checkOff = Color(0xFFD9D9D9);

  // 말풍선 + 햄스터 (439:517 / 439:527)
  static const hamsterWidth = 83.0;
  static const hamsterHeight = 60.8322;
  static const hamsterLeft = 42.0;
  static const bubbleLeft = 147.33;
  static const bubbleWidth = 205.0;
  static const bubbleHeight = 51.0;
  static const bubbleRadius = 13.0;
  static const bubbleFontSize = 16.0;

  // 뒤로가기 (439:679) — 박스 10.644×21.069, 획이 넘쳐 SVG는 15.14×25.54
  static const backBoxWidth = 10.644;
  static const backBoxHeight = 21.069;
  static const backSvgWidth = 15.1375;
  static const backSvgHeight = 25.541;
  static const backLeft = 27.0;
  // SVG가 박스보다 커서 위아래로 2.236씩 넘친다 — 박스 top(56)을 유지하려면
  // 그만큼 당겨서 그린다.
  static const backTop = 53.764; // 56 − (25.541 − 21.069) / 2

  // 입력 필드 (439:523~526) — 좌표는 화면 상단 기준 절대값
  static const fieldLeft = 36.0;
  static const fieldRight = 25.0; // 밑줄 오른쪽 끝 368.33 기준
  static const labelFontSize = 12.0;
  static const inputFontSize = 18.0;
  static const helperFontSize = 14.0;
  static const clearSize = 20.0;
  static const clearMarkSize = 8.0;
  static const underlineWidth = 345.0;
  static const underlineThickness = 2.0;
  static const eyeWidth = 20.3241;
  static const eyeHeight = 15.8953;

  // 세로 간격 (디자인 y 차이 그대로)
  static const backToHamster = 53.93; // 131 − 77.07
  static const hamsterToLabel = 32.17; // 224 − 191.83
  static const labelToInput = 29.0; // 260 − 231 (중심 간)
  static const inputToUnderline = 19.0; // 279 − 260
  // 아래 네 값은 글자 높이를 뺀 "실제로 비우는 간격"이다.
  static const underlineToHelper = 6.0; // 도움말 중심 293.5
  /// 인증 단계. 디자인은 밑줄 → 타이머(301.5) → 재전송(328.5)인데, 타이머를
  /// 빼서 재전송이 타이머 자리로 올라간다.
  static const underlineToResend = 14.0;
  static const underlineToRules = 13.8; // 규칙 1행 중심 300
  static const ruleRowGap = 13.6; // 규칙 2행 중심 328
  static const ruleColumnLeft = 36.0;
  static const ruleColumnRight = 135.0;
  static const ruleTextGap = 17.0; // 체크 → 텍스트
  static const ruleFontSize = 12.0;
  static const ruleCheckWidth = 11.7052;
  static const ruleCheckHeight = 8.31653;

  // 하단 CTA (439:521) — 키보드 위에 붙는 각진 바
  static const ctaHeight = 50.0;
  static const ctaFontSize = 18.0;

  // 약관 화면 (439:2779)
  static const termsRowLeft = 27.0;
  static const termsCircleBox = 40.0;
  static const termsCircleSize = 33.3333;
  static const termsCheckWidth = 13.3333;
  static const termsCheckHeight = 10.0;
  static const termsTextLeft = 77.0;
  static const termsFontSize = 17.0;
  static const termsFirstRowTop = 252.0;
  static const termsRowPitch = 78.0;
  static const termsChevronWidth = 14.8016;
  static const termsChevronHeight = 7.97314;
  static const termsChevronRight = 34.0; // 393 − 345 − 14
  static const termsCtaHorizontal = 24.0;
  static const termsCtaRadius = 13.0;
  static const termsCtaBottom = 54.0; // 852 − 748 − 50

  // 초기 화면 (102:12145)
  static const introHamsterTop = 211.0;
  static const introHamsterWidth = 193.406;
  static const introHamsterHeight = 213.0;
  static const introDotLeft = 194.41;
  static const introDotTop = 155.14;
  static const introDotWidth = 3.33435;
  static const introDotHeight = 5.79365;
  static const introButtonLeft = 23.33;
  static const introButtonWidth = 345.0;
  static const introButtonHeight = 48.0;
  static const introButtonRadius = 13.0;
  static const introButtonGap = 12.0; // 541 − 481 − 48
  static const introFirstButtonTop = 481.0;
  static const introHamsterToButton = 57.0; // 481 − (211 + 213)
  static const introButtonToLogin = 32.0;
  static const introButtonFontSize = 16.0;
  static const introKakaoIconWidth = 15.0;
  static const introKakaoIconHeight = 14.0;
  static const introAppleIconWidth = 23.0;
  static const introAppleIconHeight = 21.0;
  static const introGoogleIconWidth = 16.0;
  static const introGoogleIconHeight = 15.0;
  static const introIconTextGap = 7.0;

  static TextStyle bubbleStyle(double scale) => TextStyle(
    fontSize: bubbleFontSize * scale,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static TextStyle labelStyle(double scale) => TextStyle(
    fontSize: labelFontSize * scale,
    fontWeight: FontWeight.w700,
    color: accent,
  );

  static TextStyle inputStyle(double scale, {Color color = Colors.black}) =>
      TextStyle(
        fontSize: inputFontSize * scale,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle helperStyle(double scale, {Color color = accent}) =>
      TextStyle(
        fontSize: helperFontSize * scale,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle ruleStyle(double scale, {required Color color}) => TextStyle(
    fontSize: ruleFontSize * scale,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle ctaStyle(double scale) => TextStyle(
    fontSize: ctaFontSize * scale,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle termsStyle(double scale) => TextStyle(
    fontSize: termsFontSize * scale,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle introButtonStyle(double scale, {required Color color}) =>
      TextStyle(
        fontSize: introButtonFontSize * scale,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
