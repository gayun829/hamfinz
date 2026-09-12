import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/figma_assets.dart';
import '../../theme/figma_quiz_streak_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';
import '../../widgets/figma/figma_scale.dart';
import '../../widgets/quiz_figma_cta_button.dart';

const _degrees = math.pi / 180;

/// 뒤쪽 햇살 광선 하나. 크기·라운드는 전부 같고 위치·각도·색만 다르다.
class _Ray {
  const _Ray(this.center, this.rotation, {this.faded = true});

  /// 회전 전 기준 중심(design px).
  final Offset center;
  final double rotation;

  /// 흐린 민트(42%)인지, 진한 하늘색인지.
  final bool faded;
}

// Figma `293:1649`의 z-order 그대로. 중간에 ray_hub(293:1658)가 끼어 있다.
const _raysBelowHub = <_Ray>[
  _Ray(Offset(1.048, 282.52), -130.15),
  _Ray(Offset(192.48, 303.788), -40.15),
  _Ray(Offset(96.131, 335.431), 2.8, faded: false),
  _Ray(Offset(207.755, 110.486), 51.02),
  _Ray(Offset(16.806, 85.315), 141.02),
];

const _raysAboveHub = <_Ray>[
  _Ray(Offset(236.405, 204.163), 93.97, faded: false),
  _Ray(Offset(-30.535, 185.633), 93.97, faded: false),
  _Ray(Offset(113.783, 55.635), -176.03, faded: false),
];

/// 퀴즈_완료 축하창 다음에 뜨는 연속학습일 안내창.
///
/// Figma node `293:1649` 퀴즈_중간 학습창. 디자인의 `14`는 목업 값이고,
/// 실제로는 세션 완료 결과의 연속학습일([streak])을 그대로 보여준다.
class QuizStreakScreen extends StatelessWidget {
  const QuizStreakScreen({
    super.key,
    required this.streak,
    required this.onContinue,
  });

  /// 실제 연속학습일. `QuizSessionResult.newStreak`.
  final int streak;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaQuizStreakTokens.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final figma = FigmaScale.ofWidth(
            constraints.maxWidth,
            designWidth: FigmaQuizStreakTokens.designWidth,
          );
          // 원형 배경이 프레임 위/왼쪽으로 흘러넘치므로 위를 기준으로 붙이고,
          // 남는 세로 여백은 버튼 아래로 보낸다.
          final height = math.max(
            figma.s(FigmaQuizStreakTokens.designHeight),
            constraints.maxHeight,
          );

          return SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                FigmaBox(
                  figma: figma,
                  left: -263,
                  top: -177,
                  width: 741,
                  height: 741,
                  child: FigmaSvg(
                    FigmaAssets.quizStreakCircleOuter,
                    width: figma.s(741),
                    height: figma.s(741),
                    fit: BoxFit.fill,
                  ),
                ),
                FigmaBox(
                  figma: figma,
                  left: -167,
                  top: -77,
                  width: 539,
                  height: 543,
                  child: FigmaSvg(
                    FigmaAssets.quizStreakCircleInner,
                    width: figma.s(539),
                    height: figma.s(543),
                    fit: BoxFit.fill,
                  ),
                ),
                ..._raysBelowHub.map((ray) => _buildRay(figma, ray)),
                _buildRotatedAsset(
                  figma,
                  asset: FigmaAssets.quizStreakRayHub,
                  center: const Offset(104.519, 197.129),
                  size: const Size(34.185, 34.185),
                  rotation: 51.02,
                ),
                ..._raysAboveHub.map((ray) => _buildRay(figma, ray)),
                QuizFigmaCtaButton(
                  figma: figma,
                  label: '다음으로',
                  onTap: onContinue,
                ),
                _buildStreakText(figma),
                _buildSparkle(
                  figma,
                  FigmaAssets.quizStreakSparkleBlue,
                  45,
                  644,
                ),
                _buildSparkle(
                  figma,
                  FigmaAssets.quizStreakSparkleWhite,
                  201,
                  485,
                ),
                _buildRotatedAsset(
                  figma,
                  asset: FigmaAssets.quizStreakCloud,
                  center: const Offset(11.755, 388.64),
                  size: const Size(117.798, 95.3212),
                  rotation: 14.15,
                ),
                _buildRotatedAsset(
                  figma,
                  asset: FigmaAssets.quizStreakHamster,
                  center: const Offset(211.555, 361.975),
                  size: const Size(266.246, 279.191),
                  rotation: -0.59,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRay(FigmaScale figma, _Ray ray) {
    const size = FigmaQuizStreakTokens.raySize;
    return FigmaBox(
      figma: figma,
      left: ray.center.dx - size.width / 2,
      top: ray.center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Transform.rotate(
        angle: ray.rotation * _degrees,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ray.faded
                ? FigmaQuizStreakTokens.rayMint.withValues(
                    alpha: FigmaQuizStreakTokens.rayMintOpacity,
                  )
                : FigmaQuizStreakTokens.raySky,
            borderRadius: BorderRadius.circular(
              figma.s(FigmaQuizStreakTokens.rayRadius),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotatedAsset(
    FigmaScale figma, {
    required String asset,
    required Offset center,
    required Size size,
    required double rotation,
  }) {
    return FigmaBox(
      figma: figma,
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Transform.rotate(
        angle: rotation * _degrees,
        child: FigmaSvg(
          asset,
          width: figma.s(size.width),
          height: figma.s(size.height),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  /// Figma는 33×33 박스 안에 11.4% 인셋으로 별을 넣는다.
  Widget _buildSparkle(
    FigmaScale figma,
    String asset,
    double left,
    double top,
  ) {
    return FigmaBox(
      figma: figma,
      left: left,
      top: top,
      width: 33,
      height: 33,
      child: Center(
        child: FigmaSvg(
          asset,
          width: figma.s(25.4738),
          height: figma.s(25.4738),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  /// `{streak} day` / `streak!`. 자릿수가 바뀌어도 묶음이 같이 움직이도록
  /// 절대 좌표 대신 흐름 배치로 두고, 묶음 중심만 Figma 값에 맞춘다.
  Widget _buildStreakText(FigmaScale figma) {
    return FigmaBox(
      figma: figma,
      left:
          FigmaQuizStreakTokens.streakBlockCenterX -
          FigmaQuizStreakTokens.designWidth / 2,
      top: FigmaQuizStreakTokens.streakBlockTop,
      width: FigmaQuizStreakTokens.designWidth,
      height: FigmaQuizStreakTokens.streakBlockHeight,
      // 연속학습일이 세 자리를 넘어가면 프레임 밖으로 나가므로 줄여서 담는다.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: figma.s(
                      FigmaQuizStreakTokens.streakNumberFontSize,
                    ),
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: FigmaQuizStreakTokens.streakNumberColor,
                  ),
                ),
                SizedBox(width: figma.s(FigmaQuizStreakTokens.streakDayGap)),
                Text(
                  'day',
                  style: TextStyle(
                    fontSize: figma.s(FigmaQuizStreakTokens.streakDayFontSize),
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: FigmaQuizStreakTokens.streakLabelColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: figma.s(FigmaQuizStreakTokens.streakSuffixGap)),
            Text(
              'streak!',
              style: TextStyle(
                fontSize: figma.s(FigmaQuizStreakTokens.streakSuffixFontSize),
                height: 1,
                fontWeight: FontWeight.w400,
                color: FigmaQuizStreakTokens.streakLabelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
