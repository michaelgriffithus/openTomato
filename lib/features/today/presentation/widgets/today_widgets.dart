import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../contracts/today_contract.dart';

Color toneColor(AppPalette p, StatusTone tone) => switch (tone) {
      StatusTone.good => p.statusOptimalText,
      StatusTone.near => p.statusHighText,
      StatusTone.bad => p.statusOutOfRangeText,
      StatusTone.muted => p.textSecondary,
    };

Color toneFill(AppPalette p, StatusTone tone) => switch (tone) {
      StatusTone.good => p.statusOptimalFill,
      StatusTone.near => p.statusHighFill,
      StatusTone.bad => p.statusOutOfRangeFill,
      StatusTone.muted => p.trendRowFill,
    };

class ReadingTileRow extends StatelessWidget {
  final List<ReadingTile> readings;

  const ReadingTileRow({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < readings.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _ReadingTile(tile: readings[i])),
        ],
      ],
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final ReadingTile tile;

  const _ReadingTile({required this.tile});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = toneColor(palette, tile.tone);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: toneFill(palette, tile.tone),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tile.label.toUpperCase(),
            style: AppTextStyles.sectionLabel
                .copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  tile.valueText,
                  style: AppTextStyles.heroNumeral
                      .copyWith(fontSize: 30, color: palette.textPrimary),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                tile.unitText,
                style: AppTextStyles.labelSmall
                    .copyWith(color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tile.statusLabel,
            style: AppTextStyles.labelMedium
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(
            tile.bandText,
            style:
                AppTextStyles.labelSmall.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class FocusLineCard extends StatelessWidget {
  final String text;

  const FocusLineCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCardLight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: palette.heroAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style:
                  AppTextStyles.bodyLarge.copyWith(color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeInRangeCard extends StatelessWidget {
  final List<TimeInRangeTile> tiles;
  final String windowLabel;
  final ValueChanged<bool> onToggleWindow;
  final bool isDay;

  const TimeInRangeCard({
    super.key,
    required this.tiles,
    required this.windowLabel,
    required this.onToggleWindow,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCardLight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TIME IN RANGE',
                  style: AppTextStyles.sectionLabel
                      .copyWith(color: palette.textSecondary),
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('24h')),
                  ButtonSegment(value: false, label: Text('7d')),
                ],
                selected: {isDay},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (s) => onToggleWindow(s.first),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tiles.isEmpty)
            Text(
              'No readings in this window yet.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: palette.textSecondary),
            )
          else
            for (final tile in tiles) _TirRow(tile: tile),
        ],
      ),
    );
  }
}

class _TirRow extends StatelessWidget {
  final TimeInRangeTile tile;

  const _TirRow({required this.tile});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pct = tile.pct;
    final color = pct == null
        ? palette.textSecondary
        : pct >= 80
            ? palette.statusOptimalText
            : pct >= 50
                ? palette.statusHighText
                : palette.statusOutOfRangeText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(tile.label, style: AppTextStyles.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct == null ? 0 : pct / 100,
                minHeight: 8,
                backgroundColor: palette.rangeBarLow,
                color: tile.coverageOk ? color : color.withValues(alpha: .45),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              pct == null ? '--' : '${pct.round()} %',
              textAlign: TextAlign.right,
              style: AppTextStyles.labelLarge
                  .copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayPlantsStrip extends StatelessWidget {
  final List<TodayPlantChip> plants;
  final ValueChanged<int> onOpen;
  final VoidCallback onAdd;

  const TodayPlantsStrip({
    super.key,
    required this.plants,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final plant in plants)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.grass, size: 16),
                label: Text('${plant.name} · ${plant.stageLabel}'),
                onPressed: () => onOpen(plant.id),
              ),
            ),
          ActionChip(
            avatar: Icon(Icons.add, size: 16, color: palette.heroAccent),
            label: Text(plants.isEmpty ? 'Add a plant' : 'Add'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
