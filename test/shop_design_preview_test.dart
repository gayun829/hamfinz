import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:testapp/theme/app_theme.dart';
import 'package:testapp/data/shop_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/shop/shop_screen.dart';
import 'package:testapp/screens/shop/closet_screen.dart';

void main() {
  testWidgets('render shop and catalog at reference size', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      final loader = FontLoader('Pretendard')
        ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final profile = UserProfile(
      email: 'a@b.c',
      nickname: '테스트',
      seeds: 99999,
      ownedShopItemIds: ['skin_bearded_cream'],
    );
    final screens = <String, Widget>{
      'shop': ShopScreen(profile: profile),
      'catalog': ClosetScreen(profile: profile, showCatalog: true),
      'closet': ClosetScreen(profile: profile),
    };
    for (final entry in screens.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: entry.value,
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        for (final path in [
          'assets/figma/shop/closet_banner_hamster.png',
          'assets/figma/shop/clothing_shop_hamster.png',
          'assets/figma/shop/tongnamu.png',
          'assets/figma/shop/gibonbaegyoung.png',
          ...ShopData.items
              .where(
                (i) => i.assetPath != null && !i.assetPath!.endsWith('.svg'),
              )
              .map((i) => i.assetPath!),
        ]) {
          if (!context.mounted) return;
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (entry.key == 'catalog') {
        await tester.tap(
          find.byKey(const ValueKey('shop-item-skin_bearded_gray')),
        );
        await tester.pumpAndSettle();
        expect(find.text('구매하기'), findsOneWidget);
      }
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/shop-preview/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
