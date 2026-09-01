import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/enums/growth_stage.dart';

class StageBadge extends StatelessWidget {
  final GrowthStage stage;

  const StageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stage.color, width: 1),
      ),
      child: Text(
        stage.displayName,
        style: AppTextStyles.labelSmall.copyWith(color: stage.color),
      ),
    );
  }
}
