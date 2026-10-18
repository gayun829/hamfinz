import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testapp/widgets/fade_indexed_stack.dart';

void main() {
  Future<void> pump(WidgetTester tester, int index) => tester.pumpWidget(
        MaterialApp(
          home: FadeIndexedStack(
            index: index,
            children: const [Text('뉴스'), Text('홈'), Text('마이')],
          ),
        ),
      );

  double opacityOf(WidgetTester tester, String label) => tester
      .widget<AnimatedOpacity>(
        find.ancestor(of: find.text(label), matching: find.byType(AnimatedOpacity)),
      )
      .opacity;

  testWidgets('뒤쪽 탭으로 가도 나가는 탭이 끝까지 사라진다', (tester) async {
    await pump(tester, 1);
    // 홈(1)이 뉴스(0)보다 위에 그려진다. 홈의 페이드가 멈추면 뉴스를 덮는다.
    await pump(tester, 0);
    await tester.pumpAndSettle();

    expect(opacityOf(tester, '뉴스'), 1);
    expect(opacityOf(tester, '홈'), 0);
    final home = tester.renderObject<RenderAnimatedOpacity>(
      find.ancestor(of: find.text('홈'), matching: find.byType(AnimatedOpacity)),
    );
    expect(home.opacity.value, 0);
  });
}
