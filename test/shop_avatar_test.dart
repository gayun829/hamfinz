import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/shop_data.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/shop/closet_screen.dart';
import 'package:testapp/screens/shop/item_preview_screen.dart';
import 'package:testapp/widgets/shop/shop_widgets.dart';

void main() {
  testWidgets('every skin composes with every accessory on the same canvas', (
    tester,
  ) async {
    for (final skin in ShopData.byCategory(ShopCategory.skin)) {
      for (final accessory in ShopData.byCategory(ShopCategory.accessory)) {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 200,
              height: 200,
              child: ShopAvatar(skinId: skin.id, accessoryIds: [accessory.id]),
            ),
          ),
        );
        final body = find.byKey(ValueKey(skin.id));
        final overlay = find.byKey(ValueKey(accessory.id));
        expect(body, findsOneWidget);
        expect(overlay, findsOneWidget);
        expect(tester.getRect(body), tester.getRect(overlay));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
    'free default is in an empty closet and owned cards fit a small phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: ClosetScreen(
            profile: UserProfile(email: 'a@b.c', nickname: '테스트'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('기본 햄핀'), findsOneWidget);
      expect(find.text('기본 제공'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed equip stays on preview', (tester) async {
    final item = ShopData.items.first;
    await tester.pumpWidget(
      MaterialApp(
        home: ItemPreviewScreen(
          item: item,
          profile: UserProfile(email: 'a@b.c', nickname: '테스트'),
          catalogItems: ShopData.items,
          onPurchase: () async => false,
        ),
      ),
    );
    await tester.tap(find.text('착용하기'));
    await tester.pumpAndSettle();
    expect(find.text('미리보기'), findsOneWidget);
    expect(find.text('구매 완료!'), findsNothing);
  });
}
