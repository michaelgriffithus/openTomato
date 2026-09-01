import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

class AppPageTitle extends StatelessWidget {
  final String pageName;
  final Color? brandColor;
  final Color? pageColor;

  const AppPageTitle({
    super.key,
    required this.pageName,
    this.brandColor,
    this.pageColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final brandTextColor = brandColor ?? colors.textPrimary;
    final pageTextColor = pageColor ?? colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/brand/opentomato-icon.png',
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 14,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'OpenTomato ',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: brandTextColor,
                  ),
                ),
                TextSpan(
                  text: pageName,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w500,
                    color: pageTextColor,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
