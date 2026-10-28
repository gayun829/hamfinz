import 'dart:math';

import 'package:flutter/material.dart';

import '../../../constants/figma_assets.dart';
import '../../../theme/figma_onboarding_tokens.dart';

/// 앱을 열면 가장 먼저 뜨는 로고 화면 (Figma 로고+햄핀 등장창 3종).
///
/// 초록 바닥(`537:511`)·파란 바닥(`537:599`)·씨앗(`537:429`) 중 하나를 앱을
/// 켤 때마다 무작위로 고른다. 세 판 모두 벡터 20개가 넘어서 프레임을 PNG 한
/// 장씩으로 내보냈다. 배경 그라데이션을 같이 깔아 두면 화면 비율이 달라도
/// 이음매가 거의 보이지 않는다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _variants = [
    _SplashVariant(
      FigmaAssets.onboardingSplashGreen,
      FigmaOnboardingTokens.splashGreenGradient,
      FigmaOnboardingTokens.splashGreenStops,
    ),
    _SplashVariant(
      FigmaAssets.onboardingSplashBlue,
      FigmaOnboardingTokens.splashBlueGradient,
      FigmaOnboardingTokens.splashBlueStops,
    ),
    _SplashVariant(
      FigmaAssets.onboardingSplashSeed,
      FigmaOnboardingTokens.splashSeedGradient,
      FigmaOnboardingTokens.splashSeedStops,
    ),
  ];

  // static final은 처음 읽을 때 한 번만 정해진다 — 앱을 켜는 동안 스플래시가
  // 다시 그려져도 같은 판이 유지된다.
  static final _roll = Random().nextInt(_variants.length);

  @override
  Widget build(BuildContext context) {
    // 씨앗 판은 씨앗이 좌우 끝까지 꽉 차 있어서, 디자인보다 넓은 화면(태블릿)
    // 에서는 양옆이 잘린 채로 보인다. 그때는 초록·파랑 중에서만 고른다.
    final size = MediaQuery.sizeOf(context);
    final isWide =
        size.width / size.height >
        FigmaOnboardingTokens.designWidth / FigmaOnboardingTokens.designHeight +
            0.01;
    final variant = isWide ? _variants[_roll % 2] : _variants[_roll];
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: variant.gradient,
            stops: variant.stops,
          ),
        ),
        // 화면이 디자인보다 길면 남는 높이를 위쪽 배경으로 보낸다 — 씨앗 판은
        // 씨앗이 화면 아래 끝에 붙어 있어야 한다.
        child: SizedBox.expand(
          child: Image.asset(
            variant.asset,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _SplashVariant {
  const _SplashVariant(this.asset, this.gradient, this.stops);

  final String asset;
  final List<Color> gradient;
  final List<double> stops;
}
