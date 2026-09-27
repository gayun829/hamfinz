import 'package:flutter/material.dart';

import '../constants/figma_assets.dart';
import 'figma/figma_asset_image.dart';
import 'figma/figma_canvas.dart';
import 'figma/figma_scale.dart';

/// Figma `131:5346` 하단 탭 — [MainShell]에서 모든 탭에 공통 표시.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const designWidth = FigmaScale.homeDesignWidth;
  static const designHeight =
      FigmaScale.homeDesignHeight - FigmaScale.homeContentHeight;

  /// 화면 폭 [width]에서 하단 탭이 차지하는 높이.
  static double heightFor(double width) =>
      FigmaScale.ofWidth(width, designWidth: designWidth).s(designHeight);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = heightFor(constraints.maxWidth);

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: FigmaCanvas(
            designWidth: designWidth,
            designHeight: designHeight,
            scrollable: false,
            backgroundColor: Colors.white,
            builder: (context, figma) => buildHomeBottomNavLayers(
              figma: figma,
              currentNavIndex: currentIndex,
              onNavTap: onTap,
            ),
          ),
        );
      },
    );
  }
}

List<Widget> buildHomeBottomNavLayers({
  required FigmaScale figma,
  required int currentNavIndex,
  required ValueChanged<int> onNavTap,
}) {
  return [
    FigmaBox(
      figma: figma,
      left: 0,
      top: 0,
      width: HomeBottomNav.designWidth,
      height: HomeBottomNav.designHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE5E5E5).withValues(alpha: 0.6),
              blurRadius: figma.s(6.1),
              offset: Offset(0, -figma.s(2)),
            ),
          ],
        ),
      ),
    ),
    for (final (index, tab) in _tabs.indexed)
      FigmaTapArea(
        figma: figma,
        left: tab.left,
        top: tab.top,
        width: tab.width,
        height: tab.height,
        onTap: () => onNavTap(index),
        child: FigmaSvg(
          currentNavIndex == index ? tab.onAsset : tab.offAsset,
          fit: BoxFit.contain,
        ),
      ),
  ];
}

/// 탭 아이콘 위치 (하단 탭 top 기준 Figma 좌표) — 0 뉴스, 1 홈, 2 마이페이지.
const _tabs = [
  (
    left: 39.0,
    top: 7.0,
    width: 23.86,
    height: 25.81,
    onAsset: FigmaAssets.tabNewsOn,
    offAsset: FigmaAssets.tabNewsOff,
  ),
  (
    left: 185.11,
    top: 8.32,
    width: 28.06,
    height: 23.12,
    onAsset: FigmaAssets.tabHomeOn,
    offAsset: FigmaAssets.tabHomeOff,
  ),
  (
    left: 327.01,
    top: 9.59,
    width: 28.64,
    height: 19.44,
    onAsset: FigmaAssets.tabMyOn,
    offAsset: FigmaAssets.tabMyOff,
  ),
];
