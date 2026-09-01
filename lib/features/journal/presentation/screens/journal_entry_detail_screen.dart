import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/router_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_paths.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/missing_photo_placeholder.dart';
import '../../data/models/journal_entry_with_details.dart';
import '../providers/journal_providers.dart';
import '../widgets/photo_carousel.dart';

class JournalEntryDetailScreen extends ConsumerWidget {
  final int entryId;

  const JournalEntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(journalEntryByIdProvider(entryId));
    return Scaffold(
      appBar: AppBar(
        title: const AppPageTitle(pageName: 'Entry'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/timeline/edit/$entryId'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: entryAsync.when(
        data: (details) => details == null
            ? const Center(child: Text('Entry not found'))
            : _Body(details: details),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This permanently deletes the entry and its photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref.read(journalRepositoryProvider).deleteEntry(entryId);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final JournalEntryDetails details;

  const _Body({required this.details});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entry = details.entry;
    final photos = details.photos;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(entry.type.icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.type.displayName,
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        Text(
          _formatTimestamp(entry.timestamp),
          style:
              AppTextStyles.bodyMedium.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: 16),
        if (photos.isNotEmpty) ...[
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  openPhotoCarousel(
                    context,
                    photoPaths: photos.map((p) => p.filePath).toList(),
                    initialIndex: index,
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(
                      AppPaths.resolveDocumentPath(
                        photos[index].thumbnailPath,
                      ),
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const MissingPhotoPlaceholder(compact: true),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (entry.content != null && entry.content!.isNotEmpty) ...[
          GlassCard(
            child: Text(entry.content!, style: AppTextStyles.bodyLarge),
          ),
          const SizedBox(height: 16),
        ],
        if (entry.hasReadings ||
            entry.watered ||
            details.nutrientRows.isNotEmpty ||
            entry.nutrients != null) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Details',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                if (entry.tempF != null)
                  _Row(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${entry.tempF!.toStringAsFixed(1)} °F',
                  ),
                if (entry.humidityPct != null)
                  _Row(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '${entry.humidityPct!.toStringAsFixed(0)} %',
                  ),
                if (entry.vpdKpa != null)
                  _Row(
                    icon: Icons.air,
                    label: 'VPD',
                    value: '${entry.vpdKpa!.toStringAsFixed(2)} kPa',
                  ),
                if (entry.soilMoisturePct != null)
                  _Row(
                    icon: Icons.grass,
                    label: 'Soil moisture',
                    value: '${entry.soilMoisturePct!.toStringAsFixed(0)} %',
                  ),
                if (entry.watered)
                  const _Row(
                    icon: Icons.opacity,
                    label: 'Watered',
                    value: 'Yes',
                  ),
                for (final row in details.nutrientRows)
                  _Row(
                    icon: Icons.science,
                    label: row.productName,
                    value: row.amount ?? '',
                  ),
                if (entry.nutrients != null)
                  _Row(
                    icon: Icons.notes,
                    label: 'Feeding notes',
                    value: entry.nutrients!,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (details.plants.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plants',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                for (final plant in details.plants)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading:
                        Icon(Icons.chevron_right, color: palette.textSecondary),
                    title: Text(plant.name, style: AppTextStyles.bodyLarge),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pushDeduped('/plants/${plant.id}');
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Created ${_formatTimestamp(entry.createdAt)}',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${t.month}/${t.day}/${t.year} at $hour:${t.minute.toString().padLeft(2, '0')} $period';
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
