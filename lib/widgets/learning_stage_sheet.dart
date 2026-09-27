import 'package:flutter/material.dart';

import '../constants/figma_assets.dart';
import '../data/learning_stages.dart';
import '../services/auth_service.dart';
import '../theme/figma_settings_tokens.dart';
import 'figma/figma_asset_image.dart';
import 'figma/figma_scale.dart';

/// 학습 과정 시트 (Figma `539:2373` 마이페이지_학습과정).
///
/// [bottomGap]만큼 아래(하단 탭)는 비워 둔다 — Figma처럼 시트가 탭 바로 위에서
/// 끝나고, 탭은 어두워지지 않는다. 탭 쪽을 눌러도 시트가 닫힌다.
Future<void> showLearningStageSheet({
  required BuildContext context,
  required int initialStage,
  required ValueChanged<int> onStageChanged,
  double bottomGap = 0,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, _) => _SheetOverlay(
        animation: animation,
        bottomGap: bottomGap,
        child: LearningStageSheet(
          initialStage: initialStage,
          onStageChanged: onStageChanged,
        ),
      ),
    ),
  );
}

class _SheetOverlay extends StatelessWidget {
  const _SheetOverlay({
    required this.animation,
    required this.bottomGap,
    required this.child,
  });

  final Animation<double> animation;
  final double bottomGap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).maybePop();
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: bottomGap,
          // 올라오는 동안 시트가 탭 위로 겹쳐 그려지지 않도록 자른다.
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FadeTransition(
                    opacity: curved,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: close,
                      child: const ColoredBox(color: FigmaSettingsTokens.scrim),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(curved),
                    child: GestureDetector(
                      onVerticalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) > 300) close();
                      },
                      child: MediaQuery.removePadding(
                        context: context,
                        removeBottom: bottomGap > 0,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (bottomGap > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomGap,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
            ),
          ),
      ],
    );
  }
}

class LearningStageSheet extends StatefulWidget {
  const LearningStageSheet({
    super.key,
    required this.initialStage,
    required this.onStageChanged,
  });

  final int initialStage;
  final ValueChanged<int> onStageChanged;

  @override
  State<LearningStageSheet> createState() => _LearningStageSheetState();
}

class _LearningStageSheetState extends State<LearningStageSheet> {
  late int _selectedStage;
  bool _saving = false;

  /// 시트 기준 Figma 좌표 (시트 top = 305.4). 단계 칩은 90px 간격 4열.
  static const _chipLefts = [28.0, 118.0, 208.0, 298.0];
  static const _tiers = [
    (LearningStageTier.beginner, 152.8, 179.8),
    (LearningStageTier.intermediate, 252.9, 279.9),
    (LearningStageTier.advanced, 353.0, 380.1),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStage = normalizeLearningStage(widget.initialStage);
  }

  Future<void> _selectStage(int stage) async {
    if (_saving || _selectedStage == stage) return;

    setState(() => _saving = true);
    final error = await AuthService.instance.saveLearningStage(stage);

    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      _selectedStage = stage;
      _saving = false;
    });
    widget.onStageChanged(stage);
  }

  @override
  Widget build(BuildContext context) {
    final figma = FigmaScale.ofContext(
      context,
      designWidth: FigmaSettingsTokens.designWidth,
    );
    final s = figma.s;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: s(FigmaSettingsTokens.sheetHeight) + bottomInset,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(s(FigmaSettingsTokens.sheetRadius)),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: s(15.6),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: s(53),
                  height: s(5),
                  decoration: BoxDecoration(
                    color: FigmaSettingsTokens.sheetHandle,
                    borderRadius: BorderRadius.circular(s(31)),
                  ),
                ),
              ),
            ),
            FigmaBox(
              figma: figma,
              left: 31,
              top: 50.7,
              child: Text(
                '학습 과정',
                style: FigmaSettingsTokens.sheetTitleStyle(figma.scale),
              ),
            ),
            FigmaBox(
              figma: figma,
              left: 29,
              top: 86.7,
              child: Text(
                '1~10단계 중 하나를 선택하세요.',
                style: FigmaSettingsTokens.sheetBodyStyle(figma.scale),
              ),
            ),
            FigmaBox(
              figma: figma,
              left: 29,
              top: 109.7,
              child: Text(
                '선택한 단계 난이도 문제가 출제됩니다.',
                style: FigmaSettingsTokens.sheetBodyStyle(
                  figma.scale,
                  color: FigmaSettingsTokens.sheetHint,
                ),
              ),
            ),
            for (final (tier, labelTop, chipTop) in _tiers) ...[
              FigmaBox(
                figma: figma,
                left: 31,
                top: labelTop,
                child: Text(
                  tier.label,
                  style: FigmaSettingsTokens.sheetTierStyle(figma.scale),
                ),
              ),
              for (final (i, stage) in stagesInTier(tier).indexed)
                FigmaBox(
                  figma: figma,
                  left: _chipLefts[i],
                  top: chipTop,
                  width: 67.28,
                  height: 47.06,
                  child: _StageChip(
                    figma: figma,
                    stage: stage,
                    selectedStage: _selectedStage,
                    onTap: _saving ? null : () => _selectStage(stage),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 곰 모양 단계 칩 — 지난 단계는 연한 하늘색, 현재 단계는 진한 하늘색, 나머지는 회색.
class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.figma,
    required this.stage,
    required this.selectedStage,
    required this.onTap,
  });

  final FigmaScale figma;
  final int stage;
  final int selectedStage;
  final VoidCallback? onTap;

  Color get _color {
    if (stage == selectedStage) return FigmaSettingsTokens.stageCurrent;
    if (stage < selectedStage) return FigmaSettingsTokens.stagePassed;
    return FigmaSettingsTokens.stageLocked;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: stage == selectedStage,
      label: '$stage단계',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FigmaSvg(
              FigmaAssets.settingsStageBear,
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(_color, BlendMode.srcIn),
            ),
            // 숫자는 귀를 뺀 몸통 가운데 — 칩 중심보다 4.5px 아래.
            Padding(
              padding: EdgeInsets.only(top: figma.s(9)),
              child: Center(
                child: Text(
                  '$stage',
                  style: FigmaSettingsTokens.stageNumberStyle(figma.scale),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
