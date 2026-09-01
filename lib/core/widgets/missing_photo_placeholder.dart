import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

/// Placeholder shown when a journal photo's row still exists but its file does
/// not. Photo files live in the app's Documents container while their metadata
/// lives in the database, so the two can diverge — a restored database, an
/// interrupted import, or an OS-level container reset all leave rows pointing
/// at files that are gone. Rendering `Image.file` on a missing path throws
/// during paint, so every image built from a stored path routes its
/// `errorBuilder` here instead.
class MissingPhotoPlaceholder extends StatelessWidget {
  const MissingPhotoPlaceholder({
    super.key,
    this.label = 'Photo unavailable',
    this.compact = false,
  });

  final String label;

  /// Icon-only rendering for small surfaces (chat thumbnails, grid cells).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return Container(
      alignment: Alignment.center,
      color: colors.surface,
      child: compact
          ? Icon(
              Icons.image_not_supported_outlined,
              size: 20,
              color: colors.textSecondary,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// [Image.file] that degrades to [MissingPhotoPlaceholder] instead of throwing
/// when the file is missing or unreadable. Prefer this over a bare
/// `Image.file` anywhere the path comes from stored data.
class StoredPhoto extends StatelessWidget {
  const StoredPhoto({
    super.key,
    required this.file,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.compactPlaceholder = false,
    this.placeholderLabel = 'Photo unavailable',
  });

  final File file;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool compactPlaceholder;
  final String placeholderLabel;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: width,
        height: height,
        child: MissingPhotoPlaceholder(
          label: placeholderLabel,
          compact: compactPlaceholder,
        ),
      ),
    );
  }
}
