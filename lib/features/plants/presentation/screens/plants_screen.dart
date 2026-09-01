import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../contracts/plants_screen_contract.dart';
import '../controllers/plants_screen_controller.dart';
import '../widgets/plant_card.dart';

abstract class PlantsScreenActions {
  void openPlant(int plantId);
  void addPlant();
  void openSettings();
  Future<void> restore(int plantId);
}

class PlantsScreen extends ConsumerStatefulWidget {
  const PlantsScreen({super.key});

  @override
  ConsumerState<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends ConsumerState<PlantsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    return PlantsScreenView(
      contract: ref.watch(plantsScreenContractProvider),
      actions: _Actions(ref, context),
      showArchived: _showArchived,
      onToggleArchived: () => setState(() => _showArchived = !_showArchived),
    );
  }
}

/// Provider-free view so it can be built from a contract in tests.
class PlantsScreenView extends StatelessWidget {
  final PlantsScreenContract contract;
  final PlantsScreenActions actions;
  final bool showArchived;
  final VoidCallback onToggleArchived;

  const PlantsScreenView({
    super.key,
    required this.contract,
    required this.actions,
    required this.showArchived,
    required this.onToggleArchived,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppScreenHeader(
              eyebrow: showArchived ? 'Archived' : 'Your plants',
              title: showArchived
                  ? '${contract.archivedPlants.length} archived'
                  : '${contract.activeCount} growing',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: showArchived ? 'Show growing' : 'Show archived',
                    onPressed: onToggleArchived,
                    icon: Icon(
                      showArchived ? Icons.grass : Icons.archive_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: actions.openSettings,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, palette)),
          ],
        ),
      ),
      floatingActionButton: showArchived
          ? null
          : FloatingActionButton.extended(
              onPressed: actions.addPlant,
              icon: const Icon(Icons.add),
              label: const Text('Plant'),
            ),
    );
  }

  Widget _body(BuildContext context, AppPalette palette) {
    switch (contract.phase) {
      case PlantsScreenPhase.loading:
        return const Center(child: CircularProgressIndicator.adaptive());
      case PlantsScreenPhase.error:
        return Center(child: Text(contract.errorMessage ?? 'Something failed'));
      case PlantsScreenPhase.empty:
        return AppEmptyState(
          icon: Icons.grass,
          title: 'No plants yet',
          body: 'Add your first tomato plant to start a journal and see '
              'stage-aware readings on Today.',
          actionLabel: 'Add a plant',
          onAction: actions.addPlant,
        );
      case PlantsScreenPhase.ready:
        if (showArchived) return _archived(palette);
        return _groups(palette);
    }
  }

  Widget _groups(AppPalette palette) {
    if (contract.groups.isEmpty) {
      return AppEmptyState(
        icon: Icons.grass,
        title: 'Nothing growing',
        body: 'Every plant is archived. Add a new one or restore an old one.',
        actionLabel: 'Add a plant',
        onAction: actions.addPlant,
        secondaryLabel: 'Show archived',
        onSecondary: onToggleArchived,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        for (final group in contract.groups) ...[
          if (contract.groups.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                group.growSpaceName.toUpperCase(),
                style: AppTextStyles.sectionLabel.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          for (final plant in group.plants)
            PlantCard(
              key: ValueKey('plant-${plant.id}'),
              name: plant.name,
              subtitle: plant.varietyLabel,
              ageLabel: plant.ageLabel,
              stage: plant.stage,
              thumbnailPath: plant.thumbnailPath,
              onTap: () => actions.openPlant(plant.id),
            ),
        ],
      ],
    );
  }

  Widget _archived(AppPalette palette) {
    if (contract.archivedPlants.isEmpty) {
      return Center(
        child: Text(
          'No archived plants.',
          style:
              AppTextStyles.bodyMedium.copyWith(color: palette.textSecondary),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        for (final plant in contract.archivedPlants)
          Dismissible(
            key: ValueKey('archived-${plant.id}'),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (_) async {
              await actions.restore(plant.id);
              return false;
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              child: const Icon(Icons.unarchive_outlined),
            ),
            child: PlantCard(
              name: plant.name,
              subtitle: plant.varietyLabel,
              ageLabel: 'Swipe right to restore',
              stage: plant.stage,
              thumbnailPath: plant.thumbnailPath,
              onTap: () => actions.openPlant(plant.id),
            ),
          ),
      ],
    );
  }
}

class _Actions implements PlantsScreenActions {
  final WidgetRef ref;
  final BuildContext context;

  const _Actions(this.ref, this.context);

  @override
  void openPlant(int plantId) => context.push('/plants/$plantId');

  @override
  void addPlant() => context.push('/plants/create');

  @override
  void openSettings() => context.push('/settings');

  @override
  Future<void> restore(int plantId) =>
      ref.read(plantsScreenControllerProvider).restore(plantId);
}
