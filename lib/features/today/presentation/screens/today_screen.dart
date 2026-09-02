import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_screen_header.dart';
import '../../../environment/domain/environment_range_evaluator.dart';
import '../../../environment/presentation/providers/environment_providers.dart';
import '../../../journal/presentation/widgets/global_capture_sheet.dart';
import '../contracts/today_contract.dart';
import '../providers/today_contract_provider.dart';
import '../widgets/metric_trace_chart.dart';
import '../widgets/today_widgets.dart';

abstract interface class TodayActions {
  void selectGrowSpace(String id);
  void selectWindow(bool isDay);
  void selectTraceMetric(EnvironmentMetric metric);
  void openPlant(int id);
  void addPlant();
  void openSettings();
  void connectHomeAssistant();
  void addEntry();
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TodayView(
      contract: ref.watch(todayContractProvider),
      actions: _Actions(context, ref),
    );
  }
}

/// Provider-free view.
class TodayView extends StatelessWidget {
  final TodayContract contract;
  final TodayActions actions;

  const TodayView({super.key, required this.contract, required this.actions});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
            AppScreenHeader(
              eyebrow: 'Today',
              title: contract.growSpaceName,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (contract.growSpaceChoices.length > 1)
                    PopupMenuButton<String>(
                      tooltip: 'Grow space',
                      icon: const Icon(Icons.yard_outlined),
                      onSelected: actions.selectGrowSpace,
                      itemBuilder: (_) => [
                        for (final c in contract.growSpaceChoices)
                          PopupMenuItem(value: c.id, child: Text(c.name)),
                      ],
                    ),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: actions.openSettings,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: toneColor(palette, contract.freshnessTone),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    contract.freshnessLabel,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: palette.textSecondary),
                  ),
                ),
                Text(
                  contract.bandsOverridden
                      ? '${contract.stageLabel} · custom bands'
                      : contract.stageLabel,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: palette.heroAccent),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (contract.state == TodayState.unconfigured)
              AppEmptyState(
                icon: Icons.sensors_outlined,
                title: 'Connect Home Assistant',
                body:
                    'Point OpenTomato at the sensors you already have and Today '
                    'will show whether your tomatoes are in range for their stage.',
                actionLabel: 'Connect',
                onAction: actions.connectHomeAssistant,
                secondaryLabel: 'Add a plant first',
                onSecondary: actions.addPlant,
              )
            else ...[
              ReadingTileRow(readings: contract.readings),
              const SizedBox(height: 12),
              FocusLineCard(text: contract.focusLine),
              const SizedBox(height: 12),
              TimeInRangeCard(
                tiles: contract.timeInRange,
                windowLabel: contract.selectedWindow.label,
                isDay: contract.selectedWindow == ReadingWindow.day,
                onToggleWindow: actions.selectWindow,
              ),
              const SizedBox(height: 12),
              MetricTraceChart(
                trace: contract.trace,
                selected: contract.traceMetric,
                onSelect: actions.selectTraceMetric,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'PLANTS HERE',
              style: AppTextStyles.sectionLabel
                  .copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 8),
            TodayPlantsStrip(
              plants: contract.plants,
              onOpen: actions.openPlant,
              onAdd: actions.addPlant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions implements TodayActions {
  final BuildContext context;
  final WidgetRef ref;

  const _Actions(this.context, this.ref);

  @override
  void selectGrowSpace(String id) =>
      ref.read(selectedGrowSpaceIdProvider.notifier).state = id;

  @override
  void selectWindow(bool isDay) =>
      ref.read(selectedWindowProvider.notifier).state =
          isDay ? ReadingWindow.day : ReadingWindow.week;

  @override
  void selectTraceMetric(EnvironmentMetric metric) =>
      ref.read(selectedTraceMetricProvider.notifier).state = metric;

  @override
  void openPlant(int id) => context.push('/plants/$id');

  @override
  void addPlant() => context.push('/plants/create');

  @override
  void openSettings() => context.push('/settings');

  @override
  void connectHomeAssistant() => context.push('/settings/home-assistant');

  @override
  void addEntry() => openGlobalCaptureFlow(context);
}
