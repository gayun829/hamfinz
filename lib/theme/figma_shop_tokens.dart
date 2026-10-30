import 'package:flutter/material.dart';

/// Figma node `675:454` 아이템 상점 / `236:2338` 햄핀이 옷장 /
/// `131:2844` 아이템 구매창 / `131:2884` 아이템 구매완료창.
abstract final class FigmaShopTokens {
  static const designWidth = 393.0;
  static const designHeight = 852.0;

  static const background = Color(0xFFFBFBFB);
  static const card = Colors.white;
  static const previewBackground = Color(0xFFD9D9D9);
  static const chip = Color(0xFFD9FAFF);
  static const chipOwned = Color(0xFFFFF8D3);
  static const chipAmount = Color(0xFFEE9841);
  static const seed = Color(0xFFFFCA55);
  static const title = Colors.black;
  static const purchaseBackground = Color(0xFFBEBEBE);
  static const receiptBackground = Color(0xFFCFF2FC);
  static const receiptTitle = Color(0xFF00AFF8);
  static const purchaseAction = Color(0xFF3CC6FF);
  static const purchaseCancel = Color(0xFFDBDBDB);
  static const headerBorder = Color(0xFFE5E5E5);
  static const receiptTitleSize = 30.0;
  static const receiptMessageSize = 24.0;
  static const purchaseNameSize = 30.0;
  static const purchasePriceSize = 21.7;
  static const purchaseButtonSize = 18.0;

  static const pagePadding = 20.0;
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

  /// 옷장은 20, 상점·구매 화면은 22를 쓴다.
  static TextStyle headerTitle(double scale, {double size = 22}) => TextStyle(
    fontSize: size * scale,
    fontWeight: FontWeight.w600,
    color: title,
    height: 1.2,
  );

  static TextStyle sectionTitle(double scale) => TextStyle(
    fontSize: 18 * scale,
    fontWeight: FontWeight.w500,
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

  static TextStyle seedAmount(double scale, {double size = 17.243}) =>
      TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Pretendard'],
        fontSize: size * scale,
        fontWeight: FontWeight.w600,
        color: seed,
        height: 1,
      );

  static TextStyle tab(double scale, {required bool selected}) => TextStyle(
    fontSize: 20 * scale,
    fontWeight: FontWeight.w600,
    color: selected ? title : const Color(0xFF9D9D9D),
    height: 1.2,
  );
}
