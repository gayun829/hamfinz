import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../theme/figma_quiz_fonts.dart';
import '../../theme/figma_quiz_reward_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/quiz_figma_cta_button.dart';

/// 퀴즈_중간 학습창 다음에 뜨는 보상 확인창.
///
/// Figma node `131:3546` 퀴즈_결과보기창. 「레슨 완료!」 아래 세 수치는 각각
/// 맞춘 문제 수 · 획득한 씨앗 · 돌려받은 에너지다.
class QuizRewardScreen extends StatelessWidget {
  const QuizRewardScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.seedsEarned,
    required this.energyEarned,
    required this.onClaim,
  });

  final int correctCount;
  final int totalCount;
  final int seedsEarned;

  /// 세션 완료 보상 에너지.
  final int energyEarned;

  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: FigmaQuizRewardTokens.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final figma = FigmaScale.ofWidth(
              constraints.maxWidth,
              designWidth: FigmaQuizRewardTokens.designWidth,
            );
            // 남는 세로 여백은 버튼 아래로 보낸다 (퀴즈_중간 학습창과 같은 방식).
            final height = math.max(
              figma.s(FigmaQuizRewardTokens.designHeight),
              constraints.maxHeight,
            );

            return SizedBox(
              width: constraints.maxWidth,
              height: height,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  QuizFigmaCtaButton(
                    figma: figma,
                    label: '보상획득',
                    onTap: onClaim,
                  ),
                  _buildTitle(figma),
                  _buildAsset(
                    figma,
                    FigmaAssets.quizRewardHamsterShadow,
                    FigmaQuizRewardTokens.hamsterShadow,
                  ),
                  _buildSparkle(figma, FigmaQuizRewardTokens.sparkleLeftTop),
                  _buildSparkle(figma, FigmaQuizRewardTokens.sparkleRightTop),
                  ..._buildStats(figma),
                  _buildAsset(
                    figma,
                    FigmaAssets.quizRewardHamster,
                    FigmaQuizRewardTokens.hamster,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitle(FigmaScale figma) {
    return FigmaBox(
      figma: figma,
      left:
          FigmaQuizRewardTokens.titleCenterX -
          FigmaQuizRewardTokens.designWidth / 2,
      top: FigmaQuizRewardTokens.titleTop,
      width: FigmaQuizRewardTokens.designWidth,
      child: Text(
        '레슨 완료!',
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontFamily: FigmaQuizFonts.pretendard,
          fontSize: figma.s(FigmaQuizRewardTokens.titleFontSize),
          height: 1,
          fontWeight: FontWeight.w700,
          letterSpacing: figma.s(FigmaQuizRewardTokens.titleLetterSpacing),
          color: FigmaQuizRewardTokens.titleColor,
        ),
      ),
    );
  }

  Widget _buildAsset(FigmaScale figma, String asset, Rect box) {
    return FigmaBox(
      figma: figma,
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      child: FigmaSvg(
        asset,
        width: figma.s(box.width),
        height: figma.s(box.height),
        fit: BoxFit.fill,
      ),
    );
  }

  Widget _buildSparkle(FigmaScale figma, Offset topLeft) {
    const box = FigmaQuizRewardTokens.sparkleBox;
    return FigmaBox(
      figma: figma,
      left: topLeft.dx,
      top: topLeft.dy,
      width: box,
      height: box,
      child: Center(
        child: FigmaSvg(
          FigmaAssets.quizRewardSparkle,
          width: figma.s(FigmaQuizRewardTokens.sparkleInner),
          height: figma.s(FigmaQuizRewardTokens.sparkleInner),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  /// 왼쪽 = 맞춘 문제, 가운데 = 씨앗, 오른쪽 = 에너지.
  List<Widget> _buildStats(FigmaScale figma) {
    return [
      _buildAsset(
        figma,
        FigmaAssets.quizRewardStatCorrect,
        FigmaQuizRewardTokens.statCorrectIcon,
      ),
      _buildStatValue(
        figma,
        left: FigmaQuizRewardTokens.statCorrectTextLeft,
        top: FigmaQuizRewardTokens.statCorrectTextTop,
        text: '$correctCount/$totalCount',
        color: FigmaQuizRewardTokens.statCorrectColor,
      ),
      _buildAsset(
        figma,
        FigmaAssets.statCoin,
        FigmaQuizRewardTokens.statSeedIcon,
      ),
      _buildStatValue(
        figma,
        left: FigmaQuizRewardTokens.statSeedTextLeft,
        top: FigmaQuizRewardTokens.statSeedTextTop,
        text: '+$seedsEarned',
        color: FigmaQuizRewardTokens.statSeedColor,
      ),
      _buildAsset(
        figma,
        FigmaAssets.statEnergy,
        FigmaQuizRewardTokens.statEnergyIcon,
      ),
      _buildStatValue(
        figma,
        left: FigmaQuizRewardTokens.statEnergyTextLeft,
        top: FigmaQuizRewardTokens.statEnergyTextTop,
        text: '+$energyEarned',
        color: FigmaQuizRewardTokens.statEnergyColor,
      ),
    ];
  }

  Widget _buildStatValue(
    FigmaScale figma, {
    required double left,
    required double top,
    required String text,
    required Color color,
  }) {
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontFamily: FigmaQuizFonts.inter,
          fontSize: figma.s(FigmaQuizRewardTokens.statFontSize),
          height: FigmaQuizRewardTokens.statLineHeight,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
