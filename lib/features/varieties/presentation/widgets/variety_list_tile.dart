import 'package:flutter/material.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/enums/growth_habit.dart';
import '../../domain/enums/variety_category.dart';

class VarietyListTile extends StatelessWidget {
  final Variety variety;
  final VoidCallback onTap;

  const VarietyListTile({
    super.key,
    required this.variety,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final habit = GrowthHabit.fromStorage(variety.growthHabit).displayName;
    final category = VarietyCategory.fromStorage(variety.category).displayName;
    final dtm = variety.daysToMaturity;
    return ListTile(
      title: Text(variety.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$category · $habit${dtm == null ? '' : ' · $dtm days'}',
            style: AppTextStyles.bodySmall,
          ),
          if (variety.notes != null)
            Text(
              variety.notes!,
              style: AppTextStyles.caption.copyWith(
                color: context.palette.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: variety.userCreated
          ? const Chip(
              label: Text('Custom', style: TextStyle(fontSize: 10)),
              backgroundColor: AppColors.primaryLight,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      onTap: onTap,
    );
  }
}
