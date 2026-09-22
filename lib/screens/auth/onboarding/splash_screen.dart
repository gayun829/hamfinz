import 'package:flutter/material.dart';

import '../../../constants/figma_assets.dart';
import '../../../theme/figma_onboarding_tokens.dart';

/// 앱을 열면 가장 먼저 뜨는 로고 화면 (Figma `478:1213` 로고+햄핀 등장창).
///
/// 로고·햄핀이·씨앗이 모두 벡터 20개가 넘어서 프레임을 PNG 한 장으로 내보냈다.
/// 배경색을 같이 칠해 두면 화면 비율이 달라도 이음매가 보이지 않는다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FigmaOnboardingTokens.splashBackground,
      body: Center(
        child: Image(
          image: AssetImage(FigmaAssets.onboardingSplash),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
