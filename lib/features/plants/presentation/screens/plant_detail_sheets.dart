import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_date_time_picker.dart';

class HarvestSheetResult {
  final DateTime date;
  final String? notes;

  const HarvestSheetResult({required this.date, required this.notes});
}

class HarvestCard extends StatelessWidget {
  final DateTime harvestedAt;
  final String? notes;

  const HarvestCard({
    super.key,
    required this.harvestedAt,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassCardLight(
      child: Row(
        children: [
          Icon(Icons.shopping_basket_outlined, color: palette.heroAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harvested ${harvestedAt.month}/${harvestedAt.day}/${harvestedAt.year}',
                  style: AppTextStyles.labelLarge,
                ),
                if (notes != null && notes!.isNotEmpty)
                  Text(
                    notes!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<HarvestSheetResult?> showHarvestSheet(
  BuildContext context,
  DateTime? existing,
) {
  return showModalBottomSheet<HarvestSheetResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _HarvestSheet(initialDate: existing),
  );
}

class _HarvestSheet extends StatefulWidget {
  final DateTime? initialDate;
  const _HarvestSheet({required this.initialDate});

  @override
  State<_HarvestSheet> createState() => _HarvestSheetState();
}

class _HarvestSheetState extends State<_HarvestSheet> {
  late DateTime _date = widget.initialDate ?? DateTime.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Record a harvest', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          GlassDateTimePicker(
            value: _date,
            labelText: 'Harvest date',
            mode: DateTimePickerMode.dateOnly,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            onChanged: (picked) => setState(() => _date = picked),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. 2 lb from the first truss',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              HarvestSheetResult(
                date: _date,
                notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              ),
            ),
            child: const Text('Save harvest'),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDeletePlant(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $name?'),
      content: const Text(
        'This removes the plant and unlinks its journal entries. '
        'Archiving keeps everything.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
