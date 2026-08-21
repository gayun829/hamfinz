import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Figma node `235:479` 아이템 상점 / `235:382` 햄핀이 옷장.
abstract final class FigmaShopTokens {
  static const designWidth = 393.0;
  static const designHeight = 852.0;

  static const background = Color(0xFFFFFCF0);
  static const card = Color(0xC2D3D3D3);
  static const previewBackground = Color(0xFFD9D9D9);
  static const chip = Color(0xC2FFFFFF);
  static const seed = AppTheme.figmaYellow;
  static const title = Colors.black;

  static const pagePadding = 18.0;
  static const cardRadius = 13.0;
  static const purchaseRadius = 27.0;
  static const headerHeight = 56.0;

  static const seedIconHeader = Size(24.537, 23.768);
  static const seedIconFeatured = Size(25.939, 25.127);
  static const seedIconList = Size(19.096, 20.68);
  static const seedIconCloset = Size(18.013, 17.449);

  static const closetHamster = Size(95, 113);
  static const featuredHamster = Size(122, 142);
  static const closetPreviewHamster = Size(166, 198);
  static const resetButton = 45.0;

  static TextStyle headerTitle(double scale) => TextStyle(
        fontSize: (18 * scale).clamp(16, 20),
        fontWeight: FontWeight.w700,
        color: title,
        height: 1.2,
      );

  static TextStyle sectionTitle(double scale) => TextStyle(
        fontSize: (16 * scale).clamp(14, 18),
        fontWeight: FontWeight.w600,
        color: title,
        height: 1.2,
      );

  static TextStyle cardEyebrow(double scale) => TextStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w400,
        color: title,
        height: 1.2,
      );

  static TextStyle cardTitle(double scale) => TextStyle(
        fontSize: (22 * scale).clamp(18, 26),
        fontWeight: FontWeight.w600,
        color: title,
        height: 1.15,
      );

  static TextStyle body(double scale) => TextStyle(
        fontSize: 13 * scale,
        fontWeight: FontWeight.w400,
        color: title,
        height: 1.25,
      );

  static TextStyle seedAmount(double scale, {double size = 17.243}) => TextStyle(
        fontSize: size * scale,
        fontWeight: FontWeight.w600,
        color: seed,
        height: 1,
      );

  static TextStyle tab(double scale, {required bool selected}) => TextStyle(
        fontSize: 20 * scale,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        color: selected ? seed : title,
        height: 1.2,
      );
}
