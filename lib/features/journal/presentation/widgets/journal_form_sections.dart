import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_text_field.dart';

/// Editable state for one nutrient line.
class NutrientRowControllers {
  final TextEditingController name;
  final TextEditingController amount;

  NutrientRowControllers({String productName = '', String? amountText})
      : name = TextEditingController(text: productName),
        amount = TextEditingController(text: amountText ?? '');

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class ReadingsSection extends StatelessWidget {
  final TextEditingController tempF;
  final TextEditingController humidityPct;
  final TextEditingController vpdKpa;
  final TextEditingController soilMoisturePct;
  final bool fetching;
  final String? statusLine;
  final VoidCallback onUseCurrent;

  const ReadingsSection({
    super.key,
    required this.tempF,
    required this.humidityPct,
    required this.vpdKpa,
    required this.soilMoisturePct,
    required this.fetching,
    required this.statusLine,
    required this.onUseCurrent,
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
                  'Readings',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: fetching ? null : onUseCurrent,
                icon: fetching
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sensors, size: 16),
                label: const Text('Use current'),
              ),
            ],
          ),
          if (statusLine != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                statusLine!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: tempF,
                  labelText: 'Temp °F',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassTextField(
                  controller: humidityPct,
                  labelText: 'Humidity %',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: vpdKpa,
                  labelText: 'VPD kPa (auto)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassTextField(
                  controller: soilMoisturePct,
                  labelText: 'Soil moisture %',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NutrientRowsSection extends StatelessWidget {
  final List<NutrientRowControllers> rows;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const NutrientRowsSection({
    super.key,
    required this.rows,
    required this.onAdd,
    required this.onRemove,
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
                  'Products',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GlassTextField(
                      controller: rows[i].name,
                      labelText: 'Product',
                      hintText: 'e.g. tomato feed',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: GlassTextField(
                      controller: rows[i].amount,
                      labelText: 'Amount',
                      hintText: '10 ml',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => onRemove(i),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
