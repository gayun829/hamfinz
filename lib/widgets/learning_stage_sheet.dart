import 'package:flutter/material.dart';

import '../data/learning_stages.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

Future<void> showLearningStageSheet({
  required BuildContext context,
  required int initialStage,
  required ValueChanged<int> onStageChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LearningStageSheet(
      initialStage: initialStage,
      onStageChanged: onStageChanged,
    ),
  );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
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
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '학습과정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1~10단계 중 하나를 선택하세요. 선택한 단계 난이도 문제가 출제됩니다.\n'
              '1~3단계 → 초급 홈 · 4~7단계 → 중급 홈 · 8~10단계 → 고급 홈',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TierSection(
                      title: LearningStageTier.beginner.label,
                      stages: const [1, 2, 3],
                      selectedStage: _selectedStage,
                      saving: _saving,
                      onSelect: _selectStage,
                    ),
                    const SizedBox(height: 12),
                    _TierSection(
                      title: LearningStageTier.intermediate.label,
                      stages: const [4, 5, 6, 7],
                      selectedStage: _selectedStage,
                      saving: _saving,
                      onSelect: _selectStage,
                    ),
                    const SizedBox(height: 12),
                    _TierSection(
                      title: LearningStageTier.advanced.label,
                      stages: const [8, 9, 10],
                      selectedStage: _selectedStage,
                      saving: _saving,
                      onSelect: _selectStage,
                    ),
                  ],
                ),
              ),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TierSection extends StatelessWidget {
  const _TierSection({
    required this.title,
    required this.stages,
    required this.selectedStage,
    required this.saving,
    required this.onSelect,
  });

  final String title;
  final List<int> stages;
  final int selectedStage;
  final bool saving;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final stage in stages)
              _StageChip(
                stage: stage,
                selected: selectedStage == stage,
                onTap: saving ? null : () => onSelect(stage),
              ),
          ],
        ),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  final int stage;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.12)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$stage',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: selected ? AppTheme.primaryGreen : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
