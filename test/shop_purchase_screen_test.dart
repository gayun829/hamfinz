import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/shop/shop_purchase_screen.dart';
import 'package:testapp/theme/app_theme.dart';
import 'package:testapp/widgets/shop/shop_widgets.dart';

void main() {
  testWidgets('system back returns completed purchase result', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Scaffold()),
    );
    var completed = false;
    final result = navigator.currentState!.push(
      ShopPurchaseRoute(
        isCompleted: () => completed,
        builder: (_) => ShopPurchaseScreen(
          itemName: '모자',
          price: 100,
          balance: () => 1000,
          avatar: const SizedBox(),
          onPurchase: () async => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('구매하기'));
    await tester.tap(find.text('구매하기'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });
  for (final size in [const Size(360, 640), const Size(393, 852)]) {
    testWidgets(
      'purchase and receipt fit $size and prevent duplicate purchases',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var calls = 0;
        var balance = 1000;
        final result = Completer<bool>();
        await tester.pumpWidget(
          MaterialApp(
            home: ShopPurchaseScreen(
              itemName: '닌자 옷',
              price: 150,
              balance: () => balance,
              avatar: const ShopAvatar(
                patternId: 'clothing_ninja',
                accessoryIds: ['accessory_ninja'],
              ),
              onPurchase: () {
                calls++;
                return result.future;
              },
            ),
          ),
        );
        await tester.pump();
        final avatar = tester.widget<ShopAvatar>(find.byType(ShopAvatar));
        expect(avatar.patternId, 'clothing_ninja');
        expect(avatar.accessoryIds, ['accessory_ninja']);
        await tester.ensureVisible(find.text('구매하기'));
        await tester.tap(find.text('구매하기'));
        await tester.pump();
        expect(find.text('구매 중…'), findsOneWidget);
        await tester.tap(find.text('구매 중…'));
        await tester.pump();
        expect(calls, 1);
        balance = 850;
        result.complete(true);
        await tester.pumpAndSettle();
        expect(find.text('구매 완료'), findsOneWidget);
        expect(find.text('850'), findsOneWidget);
        expect(find.text('닌자 옷을 얻었어요!'), findsOneWidget);
        expect(
          tester.widget<ShopAvatar>(find.byType(ShopAvatar)).patternId,
          'clothing_ninja',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('failed purchase stays on confirmation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopPurchaseScreen(
          itemName: '모자',
          price: 100,
          balance: () => 1000,
          avatar: const ShopAvatar(),
          onPurchase: () async => false,
        ),
      ),
    );
    await tester.ensureVisible(find.text('구매하기'));
    await tester.tap(find.text('구매하기'));
    await tester.pumpAndSettle();
    expect(find.text('구매 완료'), findsNothing);
    expect(find.text('구매하기'), findsOneWidget);
  });
  testWidgets('capture purchase designs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await (FontLoader('Pretendard')
            ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    var balance = 1000;
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: ShopPurchaseScreen(
            itemName: '닌자 세트',
            price: 200,
            balance: () => balance,
            avatar: const ShopAvatar(
              patternId: 'clothing_ninja',
              accessoryIds: ['accessory_ninja'],
            ),
            onPurchase: () async {
              balance = 800;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(ShopAvatar));
      for (final path in ['clothing_ninja', 'accessory_ninja']) {
        await precacheImage(
          AssetImage('assets/figma/shop/accessories/$path.png'),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    for (final name in ['purchase', 'purchase-complete']) {
      if (name == 'purchase-complete') {
        await tester.tap(find.text('구매하기'));
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/shop-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  }, skip: !const bool.fromEnvironment('SHOP_PREVIEW'));
}
