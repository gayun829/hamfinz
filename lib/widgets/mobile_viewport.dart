import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 웹·데스크톱에서 실행할 때 화면을 휴대폰 폭(약 390px)으로 제한한다.
class MobileViewport extends StatelessWidget {
  const MobileViewport({super.key, required this.child});

  final Widget? child;

  static const double maxWidth = 390;
  /// Figma auth 프레임(1212.67×2629)을 maxWidth로 스케일했을 때의 높이 + 여유.
  static const double maxHeight = 846;

  static bool get shouldApply {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldApply || child == null) {
      return child ?? const SizedBox.shrink();
    }

    return ColoredBox(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
