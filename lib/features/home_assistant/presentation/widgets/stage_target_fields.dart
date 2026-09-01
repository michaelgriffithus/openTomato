import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../environment/domain/tomato_stage_bands.dart';

/// Six text controllers for one stage's override row.
class StageTargetControllers {
  final String stageKey;
  final tempMin = TextEditingController();
  final tempMax = TextEditingController();
  final rhMin = TextEditingController();
  final rhMax = TextEditingController();
  final vpdMin = TextEditingController();
  final vpdMax = TextEditingController();

  StageTargetControllers(this.stageKey);

  void dispose() {
    for (final c in [tempMin, tempMax, rhMin, rhMax, vpdMin, vpdMax]) {
      c.dispose();
    }
  }

  double? _d(TextEditingController c) => double.tryParse(c.text.trim());

  double? get tempMinF => _d(tempMin);
  double? get tempMaxF => _d(tempMax);
  double? get humidityMinPct => _d(rhMin);
  double? get humidityMaxPct => _d(rhMax);
  double? get vpdMinKpa => _d(vpdMin);
  double? get vpdMaxKpa => _d(vpdMax);
}

/// Per-stage override editor. Empty fields mean "use the built-in band";
/// the built-in value is shown as the hint.
class StageTargetFields extends StatelessWidget {
  final List<StageTargetControllers> stages;

  const StageTargetFields({super.key, required this.stages});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stage overrides (optional)',
          style:
              AppTextStyles.labelLarge.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Leave a field empty to keep the built-in tomato band. Both min and '
          'max are needed for an override to apply.',
          style: AppTextStyles.bodySmall.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: 8),
        for (final stage in stages) _StageRow(controllers: stage),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  final StageTargetControllers controllers;

  const _StageRow({required this.controllers});

  @override
  Widget build(BuildContext context) {
    final builtin = TomatoStageBands.builtinFor(controllers.stageKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCardLight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TomatoStageBands.labelFor(controllers.stageKey),
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: 8),
            _pair(
              'Temp °F',
              controllers.tempMin,
              controllers.tempMax,
              builtin.temperatureF,
            ),
            const SizedBox(height: 6),
            _pair(
              'Humidity %',
              controllers.rhMin,
              controllers.rhMax,
              builtin.humidityPct,
            ),
            const SizedBox(height: 6),
            _pair(
              'VPD kPa',
              controllers.vpdMin,
              controllers.vpdMax,
              builtin.vpdKpa,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pair(
    String label,
    TextEditingController min,
    TextEditingController max,
    ResolvedBand band,
  ) {
    String fmt(double v) =>
        v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);
    return Row(
      children: [
        SizedBox(width: 92, child: Text(label, style: AppTextStyles.bodySmall)),
        Expanded(
          child: TextField(
            controller: min,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: fmt(band.min),
              isDense: true,
              labelText: 'min',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: max,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: fmt(band.max),
              isDense: true,
              labelText: 'max',
            ),
          ),
        ),
      ],
    );
  }
}
