import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:testapp/data/shop_data.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/shop/closet_screen.dart';
import 'package:testapp/widgets/shop/shop_widgets.dart';

void main() {
  testWidgets('owned clothes discount sets and my only shows owned items', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: ClosetScreen(
          profile: UserProfile(
            email: 'test@test.com',
            nickname: 'test',
            ownedShopItemIds: ['clothing_ninja'],
          ),
          showCatalog: true,
        ),
      ),
    );
    await tester.pump();
    for (final label in ['my', '세트', '스킨', '옷', '악세서리']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('세트'));
    await tester.pump();
    final card = tester.widget<ShopItemCard>(
      find.byKey(const ValueKey('shop-item-skin_ninja')),
    );
    expect(card.displayPrice, 80);
    await tester.tap(find.text('my'));
    await tester.pump();
    expect(
      tester
          .widgetList<ShopItemCard>(find.byType(ShopItemCard))
          .every((i) => i.owned),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('shop-item-clothing_ninja')),
      findsOneWidget,
    );
  });
  testWidgets('clothes and accessories replace only their own slot', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profile = UserProfile(
      email: 'test@test.com',
      nickname: 'test',
      ownedShopItemIds: [
        'clothing_ninja',
        'clothing_genie',
        'accessory_ninja',
        'accessory_tie',
      ],
    );
    await tester.pumpWidget(MaterialApp(home: ClosetScreen(profile: profile)));
    await tester.pump();
    await tester.tap(find.text('옷'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('shop-item-clothing_ninja')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('shop-item-clothing_genie')));
    await tester.pump();
    await tester.tap(find.text('악세서리'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('shop-item-accessory_ninja')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('shop-item-accessory_tie')));
    await tester.pump();
    final preview = tester
        .widgetList<ShopAvatar>(find.byType(ShopAvatar))
        .first;
    expect(preview.patternId, 'clothing_genie');
    expect(preview.accessoryIds, ['accessory_tie']);
    expect(profile.equippedAccessoryIds, isEmpty);
    expect(tester.takeException(), isNull);
  });
  test('bundle quote excludes owned parts and grants legacy ownership', () {
    final ninja = ShopData.find('skin_ninja')!;
    expect(ShopData.purchasePrice(ninja, []), 200);
    expect(ShopData.purchasePrice(ninja, ['clothing_ninja']), 80);
    expect(ShopData.purchasePrice(ninja, ['accessory_ninja']), 120);
    expect(ShopData.purchasePrice(ninja, ['skin_ninja']), 0);
    expect(
      ShopData.owns(ShopData.find('accessory_ninja')!, ['skin_ninja']),
      isTrue,
    );
    expect(
      ShopData.owns(ShopData.find('accessory_perm_glasses')!, ['skin_perm']),
      isTrue,
    );
  });
}
