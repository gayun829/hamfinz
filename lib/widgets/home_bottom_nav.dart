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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final figma = FigmaScale.ofWidth(
          constraints.maxWidth,
          designWidth: designWidth,
        );
        final height = figma.s(designHeight);

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
    FigmaTapArea(
      figma: figma,
      left: 39,
      top: 7,
      width: 24,
      height: 26,
      onTap: () => onNavTap(0),
      child: Opacity(
        opacity: currentNavIndex == 0 ? 1 : 0.45,
        child: FigmaPng(
          FigmaAssets.homeBeginnerNavList,
          fit: BoxFit.contain,
        ),
      ),
    ),
    FigmaTapArea(
      figma: figma,
      left: 185,
      top: 8,
      width: 28,
      height: 23,
      onTap: () => onNavTap(1),
      child: Opacity(
        opacity: currentNavIndex == 1 ? 1 : 0.45,
        child: const FigmaSvg(
          FigmaAssets.homeBeginnerNavHome,
          fit: BoxFit.contain,
        ),
      ),
    ),
    FigmaTapArea(
      figma: figma,
      left: 327,
      top: 9,
      width: 29,
      height: 19,
      onTap: () => onNavTap(2),
      child: Opacity(
        opacity: currentNavIndex == 2 ? 1 : 0.45,
        child: const FigmaSvg(
          FigmaAssets.homeBeginnerNavProfile,
          fit: BoxFit.contain,
        ),
      ),
    ),
  ];
}
