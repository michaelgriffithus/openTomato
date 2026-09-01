import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/grow_spaces_providers.dart';
import '../providers/ha_providers.dart';

class GrowSpacesScreen extends ConsumerWidget {
  const GrowSpacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final spaces = ref.watch(growSpacesStreamProvider);
    final live = ref.watch(haLiveUpdateServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const AppPageTitle(pageName: 'Grow spaces')),
      body: spaces.when(
        data: (list) => list.isEmpty
            ? AppEmptyState(
                icon: Icons.yard_outlined,
                title: 'No grow spaces',
                body:
                    'A grow space is a place with its own air: a greenhouse, a shelf, a bed.',
                actionLabel: 'Add a grow space',
                onAction: () => context.push('/settings/grow-spaces/new'),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  Text(
                    'Each grow space maps Home Assistant sensors to the readings '
                    'on Today. Plants are assigned to a grow space.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  for (final space in list)
                    _GrowSpaceCard(
                      space: space,
                      reading: live.readingsByGrowSpace[space.id],
                      onToggle: (enabled) => ref
                          .read(growSpacesRepositoryProvider)
                          .setEnabled(space.id, enabled),
                      onTap: () => context
                          .push('/settings/grow-spaces/${space.id}/edit'),
                    ),
                ],
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Could not load: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/grow-spaces/new'),
        icon: const Icon(Icons.add),
        label: const Text('Grow space'),
      ),
    );
  }
}

class _GrowSpaceCard extends StatelessWidget {
  final GrowSpace space;
  final dynamic reading;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _GrowSpaceCard({
    required this.space,
    required this.reading,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mapped = [
      if (space.tempEntityId != null) 'temperature',
      if (space.humidityEntityId != null) 'humidity',
      if (space.vpdEntityId != null) 'VPD',
      if (space.soilMoistureEntityId != null) 'soil',
    ];
    final summary = reading == null
        ? null
        : [
            if (reading.tempF != null)
              '${(reading.tempF as double).round()} °F',
            if (reading.humidityPct != null)
              '${(reading.humidityPct as double).round()} %',
            if (reading.vpdKpa != null)
              '${(reading.vpdKpa as double).toStringAsFixed(2)} kPa',
          ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCardLight(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(space.name, style: AppTextStyles.h4),
                      ),
                      if (space.isDefault)
                        Text(
                          'Default',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: palette.textSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mapped.isEmpty
                        ? 'No sensors mapped yet'
                        : 'Mapped: ${mapped.join(', ')}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: palette.textSecondary),
                  ),
                  if (summary != null && summary.isNotEmpty)
                    Text(
                      summary,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: palette.heroAccent),
                    ),
                ],
              ),
            ),
            Switch(value: space.enabled, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}
