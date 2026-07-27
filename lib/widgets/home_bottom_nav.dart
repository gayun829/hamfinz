import 'package:flutter/material.dart';

import '../constants/figma_assets.dart';
import 'figma/figma_asset_image.dart';
import 'figma/figma_canvas.dart';
import 'figma/figma_scale.dart';

/// Figma `83:3` + `83:161` 하단 네비 — [MainShell]에서 모든 탭에 공통 표시.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const designWidth = FigmaScale.homeDesignWidth;
  static const designHeight = FigmaScale.homeDesignHeight - FigmaScale.homeContentHeight;
  static const navOriginY = FigmaScale.homeContentHeight;

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
  final origin = HomeBottomNav.navOriginY;

  return [
    FigmaBox(
      figma: figma,
      left: 1,
      top: 0,
      width: HomeBottomNav.designWidth,
      height: HomeBottomNav.designHeight,
      child: const ColoredBox(color: Color(0x3872BFC2)),
    ),
    ..._bottomNavIconLayers(
      figma: figma,
      currentNavIndex: currentNavIndex,
      onNavTap: onNavTap,
      yOffset: -origin,
    ),
  ];
}

List<Widget> _bottomNavIconLayers({
  required FigmaScale figma,
  required int currentNavIndex,
  required ValueChanged<int> onNavTap,
  required double yOffset,
}) {
  final s = figma.s;

  double top(double designTop) => designTop + yOffset;

  return [
    FigmaTapArea(
      figma: figma,
      left: 66,
      top: top(2511),
      width: 74,
      height: 65,
      onTap: () => onNavTap(0),
      child: Opacity(
        opacity: currentNavIndex == 0 ? 1 : 0.72,
        child: _NavCommunityIcon(figma: figma),
      ),
    ),
    FigmaTapArea(
      figma: figma,
      left: 383,
      top: top(2517),
      width: 88,
      height: 71.461,
      onTap: () => onNavTap(1),
      child: FigmaSvg(
        FigmaAssets.navList,
        fit: BoxFit.fill,
        opacity: currentNavIndex == 1 ? 1 : 0.72,
      ),
    ),
    FigmaTapArea(
      figma: figma,
      left: 728,
      top: top(2510),
      width: 120,
      height: 80,
      onTap: () => onNavTap(2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FigmaSvg(
            FigmaAssets.navHomeA,
            width: s(76),
            height: s(70),
            fit: BoxFit.contain,
            opacity: currentNavIndex == 2 ? 1 : 0.72,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: FigmaSvg(
              FigmaAssets.navHomeB,
              width: s(52),
              height: s(48),
              fit: BoxFit.contain,
              opacity: currentNavIndex == 2 ? 1 : 0.72,
            ),
          ),
        ],
      ),
    ),
    FigmaTapArea(
      figma: figma,
      left: 1054,
      top: top(2524),
      width: 88.407,
      height: 60,
      onTap: () => onNavTap(3),
      child: FigmaSvg(
        FigmaAssets.navProfile,
        fit: BoxFit.fill,
        opacity: currentNavIndex == 3 ? 1 : 0.72,
      ),
    ),
  ];
}

class _NavCommunityIcon extends StatelessWidget {
  const _NavCommunityIcon({required this.figma});

  final FigmaScale figma;

  @override
  Widget build(BuildContext context) {
    final s = figma.s;
    return Stack(
      children: [
        _box(s, 0, 0, 57.5, 65.017, const Color(0xFF1B9CA1)),
        _box(s, 16.16, 14.66, 57.5, 65.017, const Color(0xFF46CABF)),
        _line(s, 25.93, 24.8, 37.958, 3.007),
        _line(s, 25.61, 37.94, 37.958, 3.007),
        _line(s, 25.61, 49.32, 33.072, 3.007),
        _box(s, 60.56, 49.32, 3.007, 3.007, Colors.white),
      ],
    );
  }

  Widget _box(
    double Function(double) s,
    double left,
    double top,
    double w,
    double h,
    Color color,
  ) {
    return Positioned(
      left: s(left),
      top: s(top),
      child: Container(
        width: s(w),
        height: s(h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(s(10.523)),
        ),
      ),
    );
  }

  Widget _line(
    double Function(double) s,
    double left,
    double top,
    double w,
    double h,
  ) {
    return Positioned(
      left: s(left),
      top: s(top),
      child: Container(
        width: s(w),
        height: s(h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(s(10.523)),
        ),
      ),
    );
  }
}
