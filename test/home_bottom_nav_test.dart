import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/constants/figma_assets.dart';
import 'package:testapp/widgets/figma/figma_asset_image.dart';
import 'package:testapp/widgets/home_bottom_nav.dart';

void main() {
  Future<List<String>> iconsFor(WidgetTester tester, int index) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: HomeBottomNav(currentIndex: index, onTap: (_) {}),
          ),
        ),
      ),
    );
    return tester
        .widgetList<FigmaSvg>(find.byType(FigmaSvg))
        .map((svg) => svg.asset)
        .toList();
  }

  testWidgets('only the selected tab is blue', (tester) async {
    expect(await iconsFor(tester, 0), [
      FigmaAssets.tabNewsOn,
      FigmaAssets.tabHomeOff,
      FigmaAssets.tabMyOff,
    ]);
    expect(await iconsFor(tester, 1), [
      FigmaAssets.tabNewsOff,
      FigmaAssets.tabHomeOn,
      FigmaAssets.tabMyOff,
    ]);
    expect(await iconsFor(tester, 2), [
      FigmaAssets.tabNewsOff,
      FigmaAssets.tabHomeOff,
      FigmaAssets.tabMyOn,
    ]);
  });

  testWidgets('tapping a tab reports its index', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: HomeBottomNav(currentIndex: 1, onTap: (i) => tapped = i),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FigmaSvg).first);
    expect(tapped, 0);
  });
}
