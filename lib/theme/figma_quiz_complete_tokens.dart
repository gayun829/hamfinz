import 'package:flutter/material.dart';

/// Figma node `311:325` 퀴즈_완료 축하창 (393×852) Dev Mode 토큰.
abstract final class FigmaQuizCompleteTokens {
  static const designWidth = 393.0;
  static const designHeight = 852.0;

  static const background = Color(0xFFFEFFED);

  // Ellipse 그룹 색상. 같은 색끼리 한 덩어리로 움직인다.
  static const cream = Color(0xFFFFF1D4);
  static const yellow = Color(0xFFFFF97D);
  static const cyan = Color(0xFF36E1FF);
  static const pink = Color(0xFFFF2BA0);

  /// 모든 Ellipse에 공통으로 걸린 Figma skewX 값.
  static const blobSkewDegrees = -4.69;

  static const titleFontSize = 64.0;
  static const titleLineHeight = 70.0;
  static const titleTop = 588.0;
  static const titleCenterX = 193.5;

  // 햄핀이(Group 289/290) — 회전 전 중심 좌표와 원본 SVG 크기.
  static const hamsterRotation = 14.61;
  static const hamsterOutlineCenter = Offset(202.12, 355.41);
  static const hamsterOutlineSize = Size(306.973, 289.615);
  static const hamsterCenter = Offset(202.885, 354.775);
  static const hamsterSize = Size(284.746, 270.45);

  // 등장 애니메이션.
  static const introDuration = Duration(milliseconds: 1700);
  static const blobTravel = 460.0;
}
