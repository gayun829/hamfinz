import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/models/shop_purchase_result.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/shop/closet_screen.dart';
import 'package:testapp/widgets/shop/shop_widgets.dart';

void main() {
  for (final purchaseFails in [true, false]) {
    testWidgets(
      purchaseFails
          ? 'purchase failure never claims ownership'
          : 'successful purchase with failed equip explains saved ownership',
      (tester) async {
        var saveCalls = 0;
        final profile = UserProfile(
          email: 'test@test.com',
          nickname: 'test',
          seeds: 9999,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: ClosetScreen(
              profile: profile,
              showCatalog: true,
              purchaseItem: (id) async {
                if (purchaseFails) throw StateError('purchase failed');
                profile.ownedShopItemIds = [id];
                return ShopPurchaseResult(
                  status: ShopPurchaseStatus.success,
                  ownedShopItemIds: [id],
                );
              },
              saveEquipment:
                  ({
                    required skinId,
                    required patternId,
                    required backgroundId,
                    required accessoryIds,
                  }) async {
                    saveCalls++;
                    throw StateError('save failed');
                  },
            ),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('shop-item-skin_bearded_cream')),
        );
        await tester.pump();
        await tester.tap(find.text('구매하기'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, '구매하기').last,
        );
        await tester.tap(find.widgetWithText(FilledButton, '구매하기').last);
        await tester.pumpAndSettle();
        expect(saveCalls, purchaseFails ? 0 : 1);
        expect(profile.equippedSkinId, isNull);
        expect(
          find.text(
            purchaseFails
                ? '구매하지 못했어요. 다시 시도해주세요.'
                : '구매는 완료됐지만 착용을 저장하지 못했어요. 옷장에서 다시 착용해주세요.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('closet save failure preserves staging and persisted profile', (
    tester,
  ) async {
    final profile = UserProfile(
      email: 'test@test.com',
      nickname: 'test',
      ownedShopItemIds: ['skin_bee'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ClosetScreen(
          profile: profile,
          saveEquipment:
              ({
                required skinId,
                required patternId,
                required backgroundId,
                required accessoryIds,
              }) async {
                throw StateError('save failed');
              },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('shop-item-skin_bee')));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(profile.equippedSkinId, isNull);
    expect(
      tester.widgetList<ShopAvatar>(find.byType(ShopAvatar)).first.skinId,
      'skin_bee',
    );
    expect(find.text('저장하지 못했어요. 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
  });
}
