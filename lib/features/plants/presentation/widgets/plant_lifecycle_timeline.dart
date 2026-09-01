import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/enums/growth_stage.dart';

enum PlantLifecycleStageStatus { completed, current, upcoming }

class PlantLifecycleStage {
  final GrowthStage stage;
  final DateTime? movedAt;
  final PlantLifecycleStageStatus status;
  final String? detailLabel;

  const PlantLifecycleStage({
    required this.stage,
    required this.movedAt,
    required this.status,
    this.detailLabel,
  });
}

class PlantLifecycleTimeline extends StatelessWidget {
  final List<PlantLifecycleStage> stages;
  final ValueChanged<GrowthStage>? onMoveTo;

  const PlantLifecycleTimeline({
    super.key,
    required this.stages,
    this.onMoveTo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          _StageRow(
            stage: stages[i],
            isLast: i == stages.length - 1,
            onMoveTo: onMoveTo,
          ),
          if (i != stages.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  final PlantLifecycleStage stage;
  final bool isLast;
  final ValueChanged<GrowthStage>? onMoveTo;

  const _StageRow({
    required this.stage,
    required this.isLast,
    required this.onMoveTo,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stageColor = stage.stage.color;
    final isCurrent = stage.status == PlantLifecycleStageStatus.current;
    final isUpcoming = stage.status == PlantLifecycleStageStatus.upcoming;
    final lineColor =
        isUpcoming ? palette.cardBorder : stageColor.withValues(alpha: 0.35);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? stageColor
                      : stageColor.withValues(alpha: isUpcoming ? 0.08 : 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUpcoming
                        ? palette.cardBorder
                        : stageColor.withValues(alpha: isCurrent ? 1 : 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _stageIcon(stage.stage),
                  color: isCurrent
                      ? Colors.white
                      : isUpcoming
                          ? palette.textSecondary
                          : stageColor,
                  size: 18,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: lineColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.stage.displayName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: isUpcoming
                              ? palette.textSecondary
                              : palette.textPrimary,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        stage.detailLabel ?? _dateLabel(stage),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  _Pill(label: 'Current', color: stageColor)
                else if (isUpcoming && onMoveTo != null)
                  TextButton(
                    onPressed: () => onMoveTo!(stage.stage),
                    child: const Text('Move here'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _dateLabel(PlantLifecycleStage stage) {
    final date = stage.movedAt;
    if (date == null) {
      return stage.status == PlantLifecycleStageStatus.upcoming
          ? 'Not yet'
          : 'Date not recorded';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _stageIcon(GrowthStage stage) {
  return switch (stage) {
    GrowthStage.seedling => Icons.spa,
    GrowthStage.vegetative => Icons.eco,
    GrowthStage.flowering => Icons.local_florist,
    GrowthStage.fruitSet => Icons.circle_outlined,
    GrowthStage.ripening => Icons.brightness_7,
    GrowthStage.harvesting => Icons.shopping_basket_outlined,
    GrowthStage.done => Icons.check_circle_outline,
    GrowthStage.archived => Icons.archive,
  };
}

/// Builds the lifecycle rows for a plant from its recorded stage history.
List<PlantLifecycleStage> buildLifecycleStages({
  required GrowthStage current,
  required Map<GrowthStage, DateTime> movedAt,
}) {
  final ordered = GrowthStage.values
      .where((s) => s != GrowthStage.archived)
      .toList(growable: false);
  final currentIndex = ordered.indexOf(current);
  return [
    for (var i = 0; i < ordered.length; i++)
      PlantLifecycleStage(
        stage: ordered[i],
        movedAt: movedAt[ordered[i]],
        status: i < currentIndex
            ? PlantLifecycleStageStatus.completed
            : i == currentIndex
                ? PlantLifecycleStageStatus.current
                : PlantLifecycleStageStatus.upcoming,
      ),
  ];
}
