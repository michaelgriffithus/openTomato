import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/photo_error_placeholder.dart';

/// Grid of thumbnails with optional delete buttons. Paths are absolute.
class PhotoThumbnailGrid extends StatelessWidget {
  final List<String> photoPaths;
  final void Function(int)? onDelete;
  final void Function(int)? onTap;
  final int crossAxisCount;

  const PhotoThumbnailGrid({
    super.key,
    required this.photoPaths,
    this.onDelete,
    this.onTap,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPaths.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photoPaths.length,
      itemBuilder: (context, index) {
        return PhotoThumbnail(
          photoPath: photoPaths[index],
          onDelete: onDelete == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onDelete!(index);
                },
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!(index);
                },
        );
      },
    );
  }
}

class PhotoThumbnail extends StatelessWidget {
  final String photoPath;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const PhotoThumbnail({
    super.key,
    required this.photoPath,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photoPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return PhotoErrorPlaceholder(
                  iconColor: AppColors.textDisabled,
                  backgroundColor: context.palette.surface,
                );
              },
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
