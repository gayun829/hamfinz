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
    expect(find.text('아이템 상점'), findsOneWidget);
    expect(find.text('햄핀이 옷장'), findsOneWidget);
    expect(find.text('햄핀이 옷 상점'), findsOneWidget);
    expect(find.text('아이템 목록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shop fits a large phone', (tester) async {
    await pumpShop(tester, const Size(430, 932));
    expect(find.text('아이템 상점'), findsOneWidget);
    expect(find.text('햄핀이 옷 상점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('only bundled items are accepted', () {
    expect(ShopData.find('test_remote_hat'), isNull);
    expect(ShopData.find('skin_default')!.included, isTrue);
  });
}
