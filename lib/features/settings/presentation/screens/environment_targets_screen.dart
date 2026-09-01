import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../environment/data/stage_targets_settings_service.dart';
import '../../../environment/domain/tomato_stage_bands.dart';
import '../../../environment/presentation/providers/environment_providers.dart';

/// App-wide stage band overrides. A grow space can still override these.
class EnvironmentTargetsScreen extends ConsumerStatefulWidget {
  const EnvironmentTargetsScreen({super.key});

  @override
  ConsumerState<EnvironmentTargetsScreen> createState() =>
      _EnvironmentTargetsScreenState();
}

class _EnvironmentTargetsScreenState
    extends ConsumerState<EnvironmentTargetsScreen> {
  final Map<String, _Controllers> _controllers = {
    for (final key in TomatoStageBands.editableStageKeys) key: _Controllers(),
  };
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bands =
        await ref.read(stageTargetsSettingsServiceProvider).getEditableBands();
    if (!mounted) return;
    for (final entry in bands.entries) {
      _controllers[entry.key]?.setValues(entry.value);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const AppPageTitle(pageName: 'Stage targets'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _reset,
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'The bands Today judges readings against, per stage. These are '
                  'the built-in tomato defaults unless you change them; a grow '
                  'space can override them again.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 16),
                for (final key in TomatoStageBands.editableStageKeys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StageCard(
                      title: TomatoStageBands.labelFor(key),
                      controllers: _controllers[key]!,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final values = <String, EditableStageTargetBands>{};
    for (final entry in _controllers.entries) {
      final parsed = entry.value.tryParse();
      if (parsed == null || !parsed.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${TomatoStageBands.labelFor(entry.key)}: each min must be below its max.',
            ),
          ),
        );
        return;
      }
      values[entry.key] = parsed;
    }
    setState(() => _saving = true);
    await ref
        .read(stageTargetsSettingsServiceProvider)
        .saveEditableBands(values);
    ref.invalidate(stageBandsProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Stage targets saved.')));
  }

  Future<void> _reset() async {
    final service = ref.read(stageTargetsSettingsServiceProvider);
    for (final key in TomatoStageBands.editableStageKeys) {
      await service.resetStage(key);
    }
    ref.invalidate(stageBandsProvider);
    await _load();
  }
}

class _StageCard extends StatelessWidget {
  final String title;
  final _Controllers controllers;

  const _StageCard({required this.title, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _Row(
              label: 'Temp °F',
              min: controllers.tempMin,
              max: controllers.tempMax,
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'Humidity %',
              min: controllers.rhMin,
              max: controllers.rhMax,
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'VPD kPa',
              min: controllers.vpdMin,
              max: controllers.vpdMax,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final TextEditingController min;
  final TextEditingController max;

  const _Row({required this.label, required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(label),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _field(min, 'Min')),
        const SizedBox(width: 12),
        Expanded(child: _field(max, 'Max')),
      ],
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}

class _Controllers {
  final tempMin = TextEditingController();
  final tempMax = TextEditingController();
  final rhMin = TextEditingController();
  final rhMax = TextEditingController();
  final vpdMin = TextEditingController();
  final vpdMax = TextEditingController();

  void setValues(EditableStageTargetBands b) {
    tempMin.text = b.tempMinF.toStringAsFixed(0);
    tempMax.text = b.tempMaxF.toStringAsFixed(0);
    rhMin.text = b.humidityMinPct.toStringAsFixed(0);
    rhMax.text = b.humidityMaxPct.toStringAsFixed(0);
    vpdMin.text = b.vpdMinKpa.toStringAsFixed(2);
    vpdMax.text = b.vpdMaxKpa.toStringAsFixed(2);
  }

  EditableStageTargetBands? tryParse() {
    final values = [tempMin, tempMax, rhMin, rhMax, vpdMin, vpdMax]
        .map((c) => double.tryParse(c.text.trim()))
        .toList();
    if (values.any((v) => v == null)) return null;
    return EditableStageTargetBands(
      tempMinF: values[0]!,
      tempMaxF: values[1]!,
      humidityMinPct: values[2]!,
      humidityMaxPct: values[3]!,
      vpdMinKpa: values[4]!,
      vpdMaxKpa: values[5]!,
    );
  }

  void dispose() {
    for (final c in [tempMin, tempMax, rhMin, rhMax, vpdMin, vpdMax]) {
      c.dispose();
    }
  }
}
