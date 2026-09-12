import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/figma_quiz_complete_tokens.dart';
import '../../widgets/figma/figma_asset_image.dart';

const _degrees = math.pi / 180;
const _assetDir = 'assets/figma/quiz/complete';

/// 같은 색 Ellipse끼리 묶은 그룹. 그룹 하나가 한 방향에서 통째로 밀려 들어온다.
enum _BlobGroup {
  cream(Offset(0, -1), Interval(0.00, 0.45, curve: Curves.easeOutCubic)),
  yellow(Offset(1, 0), Interval(0.08, 0.53, curve: Curves.easeOutCubic)),
  cyan(Offset(-1, 0), Interval(0.16, 0.61, curve: Curves.easeOutCubic)),
  pink(Offset(0, 1), Interval(0.24, 0.69, curve: Curves.easeOutCubic));

  const _BlobGroup(this.direction, this.curve);

  /// 화면 밖 출발 방향(단위 벡터).
  final Offset direction;
  final Interval curve;
}

/// Figma Ellipse 하나. [center]/[size]는 회전 전 기준 좌표(design px)다.
class _Blob {
  const _Blob(this.group, this.name, this.center, this.size, this.rotation);

  final _BlobGroup group;
  final String name;
  final Offset center;
  final Size size;

  /// Figma CSS `rotate()` 값(deg). skew는 전 요소 공통이라 토큰에 있다.
  final double rotation;

  String get asset => '$_assetDir/ellipse_$name.svg';
}

// Figma `311:325`의 z-order 그대로. 햄핀이(311:328)와 타이틀(311:390)이
// 중간에 끼어 있어 세 덩어리로 나눠 둔다.
const _blobsBehindHamster = <_Blob>[
  _Blob(
    _BlobGroup.yellow,
    '162',
    Offset(326.294, 335.519),
    Size(270.675, 129.622),
    -35.7,
  ),
  _Blob(
    _BlobGroup.yellow,
    '163',
    Offset(316.748, 440.163),
    Size(270.675, 128.571),
    -29.6,
  ),
];

const _blobsBehindTitle = <_Blob>[
  _Blob(
    _BlobGroup.cyan,
    '164',
    Offset(6.366, 565.462),
    Size(146.099, 73.271),
    -49.29,
  ),
  // 165는 Figma에 남은 회색 원본. 169가 같은 자리·같은 크기로 완전히 덮는다.
  _Blob(
    _BlobGroup.cyan,
    '165',
    Offset(55.129, 615.727),
    Size(208.83, 115.226),
    -52.96,
  ),
  _Blob(
    _BlobGroup.cyan,
    '169',
    Offset(54.889, 615.697),
    Size(208.83, 115.226),
    -52.96,
  ),
  _Blob(
    _BlobGroup.cyan,
    '172',
    Offset(54.543, 616.015),
    Size(164.759, 90.909),
    -52.96,
  ),
  _Blob(
    _BlobGroup.cyan,
    '167',
    Offset(171.532, 629.303),
    Size(52.668, 22.862),
    -32.65,
  ),
  _Blob(
    _BlobGroup.cyan,
    '168',
    Offset(64.624, 431.871),
    Size(32.883, 20.4),
    -51.96,
  ),
  _Blob(
    _BlobGroup.pink,
    '171',
    Offset(139.959, 761.53),
    Size(368.292, 201.676),
    -26.27,
  ),
  _Blob(
    _BlobGroup.cyan,
    '166',
    Offset(48.563, 621.456),
    Size(240.982, 132.966),
    -48.9,
  ),
  _Blob(
    _BlobGroup.pink,
    '161',
    Offset(298.778, 708.299),
    Size(400.798, 229.281),
    -35.75,
  ),
  _Blob(
    _BlobGroup.cream,
    '174',
    Offset(200.18, 11.373),
    Size(341.757, 195.506),
    -44.03,
  ),
  _Blob(
    _BlobGroup.cream,
    '175',
    Offset(60.95, 21.605),
    Size(283.64, 149.21),
    -34.54,
  ),
  _Blob(
    _BlobGroup.pink,
    '170',
    Offset(343.384, 779.53),
    Size(362.135, 207.164),
    -35.75,
  ),
  _Blob(
    _BlobGroup.pink,
    '160',
    Offset(118.597, 687.092),
    Size(300.553, 158.107),
    -36.16,
  ),
];

const _blobsAboveTitle = <_Blob>[
  _Blob(
    _BlobGroup.cyan,
    '173',
    Offset(-0.131, 448.851),
    Size(99.229, 46.168),
    -45.47,
  ),
  _Blob(
    _BlobGroup.yellow,
    '177',
    Offset(380.34, 476.909),
    Size(117.321, 66.978),
    -36.09,
  ),
];

/// 퀴즈를 끝까지 푼 직후 뜨는 축하 화면. 아무 곳이나 터치하면 넘어간다.
///
/// Figma node `311:325` 퀴즈_완료 축하창.
class QuizCompleteScreen extends StatefulWidget {
  const QuizCompleteScreen({super.key, required this.onContinue});

  /// 화면을 터치했을 때 이어서 보여줄 곳으로 넘긴다.
  final VoidCallback onContinue;

  @override
  State<QuizCompleteScreen> createState() => _QuizCompleteScreenState();
}

class _QuizCompleteScreenState extends State<QuizCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FigmaQuizCompleteTokens.introDuration,
  )..forward();

  late final Map<_BlobGroup, Animation<double>> _blobIntro = {
    for (final group in _BlobGroup.values)
      group: CurvedAnimation(parent: _controller, curve: group.curve),
  };

  late final Animation<double> _hamsterIntro = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.82, curve: Curves.easeOutBack),
  );

  late final Animation<double> _titleIntro = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.62, 1, curve: Curves.easeOutCubic),
  );

  bool _leaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_leaving) return;
    _leaving = true;
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaQuizCompleteTokens.background,
      body: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        // 전면 일러스트라 여백 없이 화면을 덮어야 한다. FigmaCanvas의 contain
        // 방식은 위아래 여백이 생기므로 cover로 잘라 채운다.
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: FigmaQuizCompleteTokens.designWidth,
              height: FigmaQuizCompleteTokens.designHeight,
              child: ColoredBox(
                color: FigmaQuizCompleteTokens.background,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      ..._blobsBehindHamster.map(_buildBlob),
                      ..._buildHamster(),
                      ..._blobsBehindTitle.map(_buildBlob),
                      _buildTitle(),
                      ..._blobsAboveTitle.map(_buildBlob),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlob(_Blob blob) {
    final progress = _blobIntro[blob.group]!.value;
    final shift =
        blob.group.direction *
        FigmaQuizCompleteTokens.blobTravel *
        (1 - progress);
    final transform = Matrix4.translationValues(shift.dx, shift.dy, 0)
      ..multiply(Matrix4.rotationZ(blob.rotation * _degrees))
      ..multiply(
        Matrix4.skewX(FigmaQuizCompleteTokens.blobSkewDegrees * _degrees),
      );

    return Positioned(
      left: blob.center.dx - blob.size.width / 2,
      top: blob.center.dy - blob.size.height / 2,
      width: blob.size.width,
      height: blob.size.height,
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: FigmaSvg(
          blob.asset,
          width: blob.size.width,
          height: blob.size.height,
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  /// 흰 테두리(Group 290) 위에 본체(Group 289)를 겹친 햄핀이.
  List<Widget> _buildHamster() {
    return [
      _buildHamsterLayer(
        '$_assetDir/hamster_outline.svg',
        FigmaQuizCompleteTokens.hamsterOutlineCenter,
        FigmaQuizCompleteTokens.hamsterOutlineSize,
      ),
      _buildHamsterLayer(
        '$_assetDir/hamster.svg',
        FigmaQuizCompleteTokens.hamsterCenter,
        FigmaQuizCompleteTokens.hamsterSize,
      ),
    ];
  }

  Widget _buildHamsterLayer(String asset, Offset center, Size size) {
    final progress = _hamsterIntro.value;
    final scale = 0.62 + 0.38 * progress;
    final transform = Matrix4.rotationZ(
      FigmaQuizCompleteTokens.hamsterRotation * _degrees,
    )..scaleByDouble(scale, scale, scale, 1);

    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: transform,
          child: FigmaSvg(
            asset,
            width: size.width,
            height: size.height,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final progress = _titleIntro.value;
    const fontSize = FigmaQuizCompleteTokens.titleFontSize;

    return Positioned(
      // 텍스트 중심이 프레임 중앙(196.5)이 아니라 193.5다.
      left:
          FigmaQuizCompleteTokens.titleCenterX -
          FigmaQuizCompleteTokens.designWidth / 2,
      top: FigmaQuizCompleteTokens.titleTop,
      width: FigmaQuizCompleteTokens.designWidth,
      child: Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 36 * (1 - progress)),
          child: const Text(
            'Lesson\ncomplete!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              height: FigmaQuizCompleteTokens.titleLineHeight / fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
