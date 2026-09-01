import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_paths.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/missing_photo_placeholder.dart';
import '../../domain/enums/growth_stage.dart';
import 'stage_badge.dart';

/// Provider-free plant row. The screen contract supplies every string.
class PlantCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String ageLabel;
  final GrowthStage stage;
  final String? thumbnailPath;
  final VoidCallback onTap;

  const PlantCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.ageLabel,
    required this.stage,
    required this.thumbnailPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCardLight(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Row(
          children: [
            _Thumbnail(path: thumbnailPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: AppTextStyles.h3)),
                      StageBadge(stage: stage),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ageLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? path;

  const _Thumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    final stored = path;
    if (stored == null) return const _Placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Image.file(
          File(AppPaths.resolveDocumentPath(stored)),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const MissingPhotoPlaceholder(compact: true),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.grass,
        color: AppColors.primary.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}
