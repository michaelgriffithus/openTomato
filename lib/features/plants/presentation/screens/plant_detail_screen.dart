import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_paths.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/missing_photo_placeholder.dart';
import '../../data/repositories/plants_repository.dart';
import '../../domain/enums/growth_stage.dart';
import '../contracts/plant_detail_contract.dart';
import '../controllers/plants_screen_controller.dart';
import '../providers/plants_providers.dart';
import '../widgets/plant_lifecycle_timeline.dart';
import '../widgets/stage_badge.dart';
import 'plant_detail_sheets.dart';

abstract class PlantDetailActions {
  void back();
  void edit();
  void moveStage(GrowthStage? to);
  void openEntry(int entryId);
  void addEntry();
  Future<void> recordHarvest();
  Future<void> toggleArchive();
  Future<void> delete();
}

class PlantDetailScreen extends ConsumerWidget {
  final int plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contract = ref.watch(plantDetailContractProvider(plantId));
    return PlantDetailView(
      contract: contract,
      actions: _Actions(ref, context, contract),
    );
  }
}

/// Provider-free view.
class PlantDetailView extends StatelessWidget {
  final PlantDetailContract contract;
  final PlantDetailActions actions;

  const PlantDetailView({
    super.key,
    required this.contract,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: switch (contract.phase) {
          PlantDetailPhase.loading =>
            const Center(child: CircularProgressIndicator.adaptive()),
          PlantDetailPhase.missing => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This plant no longer exists.'),
                  TextButton(
                    onPressed: actions.back,
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          PlantDetailPhase.ready =>
            _Ready(contract: contract, actions: actions),
        },
      ),
      floatingActionButton: contract.phase == PlantDetailPhase.ready
          ? FloatingActionButton.extended(
              onPressed: actions.addEntry,
              icon: const Icon(Icons.edit_note),
              label: const Text('Log'),
              backgroundColor: palette.heroAccent,
            )
          : null,
    );
  }
}

class _Ready extends StatelessWidget {
  final PlantDetailContract contract;
  final PlantDetailActions actions;

  const _Ready({required this.contract, required this.actions});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        AppScreenHeader(
          eyebrow: contract.growSpaceLabel,
          title: contract.name,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: actions.back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          action: PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'edit' => actions.edit(),
              'stage' => actions.moveStage(null),
              'harvest' => actions.recordHarvest(),
              'archive' => actions.toggleArchive(),
              'delete' => actions.delete(),
              _ => null,
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit details')),
              const PopupMenuItem(value: 'stage', child: Text('Move stage')),
              const PopupMenuItem(
                value: 'harvest',
                child: Text('Record harvest'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(contract.isArchived ? 'Restore' : 'Archive'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                path: contract.heroImagePath,
                photoCount: contract.photoCount,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  StageBadge(stage: contract.stage),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      contract.stageDayLabel,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(contract.varietyLabel, style: AppTextStyles.h4),
              Text(
                contract.ageLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              if (contract.maturityLabel != null)
                Text(
                  contract.maturityLabel!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              if (contract.detailsLine != null) ...[
                const SizedBox(height: 6),
                Text(
                  contract.detailsLine!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
              if (contract.harvestedAt != null) ...[
                const SizedBox(height: 12),
                HarvestCard(
                  harvestedAt: contract.harvestedAt!,
                  notes: contract.harvestNotes,
                ),
              ],
              if (contract.notes != null) ...[
                const SizedBox(height: 12),
                GlassCardLight(child: Text(contract.notes!)),
              ],
              const SizedBox(height: 24),
              const _SectionLabel('Lifecycle'),
              const SizedBox(height: 8),
              PlantLifecycleTimeline(
                stages: contract.lifecycle,
                onMoveTo: actions.moveStage,
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Recent entries'),
              const SizedBox(height: 8),
              if (contract.recentEntries.isEmpty)
                Text(
                  'Nothing logged yet.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: palette.textSecondary,
                  ),
                )
              else
                for (final entry in contract.recentEntries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(entry.type.icon, color: palette.heroAccent),
                    title: Text(entry.title, maxLines: 2),
                    subtitle: Text(entry.dateLabel),
                    onTap: () => actions.openEntry(entry.id),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.sectionLabel.copyWith(
        color: context.palette.heroAccent,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String? path;
  final int photoCount;

  const _Hero({required this.path, required this.photoCount});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stored = path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: stored == null
            ? Container(
                color: palette.surface,
                alignment: Alignment.center,
                child:
                    Icon(Icons.grass, size: 48, color: palette.textSecondary),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(AppPaths.resolveDocumentPath(stored)),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const MissingPhotoPlaceholder(),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$photoCount photo${photoCount == 1 ? '' : 's'}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Actions implements PlantDetailActions {
  final WidgetRef ref;
  final BuildContext context;
  final PlantDetailContract contract;

  const _Actions(this.ref, this.context, this.contract);

  @override
  void back() => context.pop();

  @override
  void edit() => context.push('/plants/${contract.plantId}/edit');

  @override
  void moveStage(GrowthStage? to) =>
      context.push('/plants/stage-change?plantId=${contract.plantId}');

  @override
  void openEntry(int entryId) => context.push('/timeline/$entryId');

  @override
  void addEntry() => context.push('/timeline/new?plantId=${contract.plantId}');

  @override
  Future<void> recordHarvest() async {
    final result = await showHarvestSheet(context, contract.harvestedAt);
    if (result == null) return;
    await ref.read(plantsRepositoryProvider).recordHarvest(
          plantId: contract.plantId,
          harvestedAt: result.date,
          notes: result.notes,
          plantName: contract.name,
        );
    ref.invalidate(plantByIdProvider(contract.plantId));
  }

  @override
  Future<void> toggleArchive() async {
    final controller = ref.read(plantsScreenControllerProvider);
    if (contract.isArchived) {
      await controller.restore(contract.plantId);
    } else {
      await controller.archive(contract.plantId);
    }
    ref.invalidate(plantByIdProvider(contract.plantId));
  }

  @override
  Future<void> delete() async {
    final confirmed = await confirmDeletePlant(context, contract.name);
    if (!confirmed) return;
    await ref.read(plantsScreenControllerProvider).delete(contract.plantId);
    if (context.mounted) context.pop();
  }
}
