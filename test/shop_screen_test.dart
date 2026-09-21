import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/data/shop_data.dart';
import 'package:testapp/models/user_profile.dart';
import 'package:testapp/screens/shop/shop_screen.dart';

void main() {
  Future<void> pumpShop(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQueryData(size: size),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: ShopScreen(
          profile: UserProfile(email: 'a@b.c', nickname: '테스트'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shop fits a small phone', (tester) async {
    await pumpShop(tester, const Size(360, 740));
    expect(find.text('상점'), findsOneWidget);
    expect(find.text('햄핀 옷장'), findsOneWidget);
    expect(find.text('옷 상점'), findsOneWidget);
    expect(find.text('아이템 목록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shop fits a large phone', (tester) async {
    await pumpShop(tester, const Size(430, 932));
    expect(find.text('상점'), findsOneWidget);
    expect(find.text('옷 상점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('parses a Firebase-only item without changing local items', () {
    final item = ShopItem.fromFirestore('new_hat', {
      'name': '테스트 모자',
      'description': 'Firebase 테스트 아이템',
      'price': 123,
      'category': 'accessory',
      'spriteCol': 2,
      'spriteRow': 0,
      'featured': false,
      'hideFromCloset': false,
      'isActive': true,
      'sortOrder': 10,
      'imageUrl': 'https://example.com/new_hat.png',
    });

    expect(item.id, 'new_hat');
    expect(item.name, '테스트 모자');
    expect(item.price, 123);
    expect(item.category, ShopCategory.accessory);
    expect(item.imageUrl, 'https://example.com/new_hat.png');
    expect(
      ShopData.items.map((localItem) => localItem.id),
      contains('skin_default'),
    );
  });
}
