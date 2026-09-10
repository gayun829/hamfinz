import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/screens/friends/add_friend_screen.dart';

void main() {
  Future<void> pumpFriends(WidgetTester tester, Size size) async {
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
        home: const AddFriendScreen(),
      ),
    );
    await tester.pump();
  }

  testWidgets('friends screen fits a small phone', (tester) async {
    await pumpFriends(tester, const Size(360, 740));
    expect(find.text('친구'), findsOneWidget);
    expect(find.text('친구 추가하기'), findsOneWidget);
    expect(find.text('받은 요청'), findsOneWidget);
    expect(find.text('친구 목록'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('friends screen fits a large phone', (tester) async {
    await pumpFriends(tester, const Size(430, 932));
    expect(find.text('친구 추가하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
