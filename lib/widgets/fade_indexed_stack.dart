import 'package:flutter/widgets.dart';

/// [IndexedStack]처럼 탭 상태는 살려 두되, 탭이 바뀔 때 툭 끊지 않고 겹쳐 넘긴다.
class FadeIndexedStack extends StatelessWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          // 숨은 탭은 터치·스크린리더에서 빠진다.
          IgnorePointer(
            ignoring: i != index,
            child: ExcludeSemantics(
              excluding: i != index,
              child: AnimatedOpacity(
                opacity: i == index ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                // 탭 안의 애니메이션만 멈춘다. 페이드 바깥까지 멈추면 나가는 탭이
                // 다 보이는 채로 굳어서 아래 탭을 덮는다.
                child: TickerMode(enabled: i == index, child: children[i]),
              ),
            ),
          ),
      ],
    );
  }
}
