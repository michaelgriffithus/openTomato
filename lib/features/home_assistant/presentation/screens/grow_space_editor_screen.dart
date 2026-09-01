import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../environment/domain/tomato_stage_bands.dart';
import '../../data/models/ha_discovered_entity.dart';
import '../../data/repositories/grow_spaces_repository.dart';
import '../providers/ha_providers.dart';
import '../widgets/entity_picker_field.dart';
import '../widgets/stage_target_fields.dart';

class GrowSpaceEditorScreen extends ConsumerStatefulWidget {
  /// Null creates a grow space; non-null edits it.
  final String? growSpaceId;

  const GrowSpaceEditorScreen({super.key, this.growSpaceId});

  @override
  ConsumerState<GrowSpaceEditorScreen> createState() =>
      _GrowSpaceEditorScreenState();
}

class _GrowSpaceEditorScreenState extends ConsumerState<GrowSpaceEditorScreen> {
  final _name = TextEditingController();
  String? _temp;
  String? _humidity;
  String? _vpd;
  String? _soil;
  bool _isDefault = false;
  bool _loaded = false;
  bool _saving = false;
  List<HADiscoveredEntity> _entities = const [];
  String? _discoveryError;
  final List<StageTargetControllers> _stages = [
    for (final key in TomatoStageBands.editableStageKeys)
      StageTargetControllers(key),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(growSpacesRepositoryProvider);
    final id = widget.growSpaceId;
    if (id != null) {
      final space = await repo.getById(id);
      final targets = await repo.getStageTargets(id);
      if (space != null && mounted) {
        _name.text = space.name;
        _temp = space.tempEntityId;
        _humidity = space.humidityEntityId;
        _vpd = space.vpdEntityId;
        _soil = space.soilMoistureEntityId;
        _isDefault = space.isDefault;
        for (final row in targets) {
          final c =
              _stages.where((s) => s.stageKey == row.stageKey).firstOrNull;
          if (c == null) continue;
          String f(double? v) =>
              v == null ? '' : (v == v.roundToDouble() ? '${v.round()}' : '$v');
          c.tempMin.text = f(row.tempMinF);
          c.tempMax.text = f(row.tempMaxF);
          c.rhMin.text = f(row.humidityMinPct);
          c.rhMax.text = f(row.humidityMaxPct);
          c.vpdMin.text = f(row.vpdMinKpa);
          c.vpdMax.text = f(row.vpdMaxKpa);
        }
      }
    }
    if (mounted) setState(() => _loaded = true);
    try {
      final entities =
          await ref.read(haEntityDiscoveryServiceProvider).discover();
      if (mounted) setState(() => _entities = entities);
    } catch (e) {
      if (mounted) {
        setState(
          () => _discoveryError =
              e is AppException ? e.userMessage : 'Could not list sensors: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final s in _stages) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final discovery = ref.read(haEntityDiscoveryServiceProvider);
    final isEditing = widget.growSpaceId != null;
    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          pageName: isEditing ? 'Edit grow space' : 'New grow space',
        ),
        actions: [
          if (isEditing && !_isDefault)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                GlassTextField(
                  controller: _name,
                  labelText: 'Name',
                  hintText: 'e.g. Greenhouse, Seed shelf',
                ),
                const SizedBox(height: 16),
                if (_discoveryError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '$_discoveryError You can still type entity ids by hand.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: palette.statusHighText),
                    ),
                  ),
                EntityPickerField(
                  label: 'Temperature',
                  required: true,
                  value: _temp,
                  candidates: discovery.candidatesForTemperature(_entities),
                  all: _entities,
                  onChanged: (v) => setState(() => _temp = v),
                ),
                const SizedBox(height: 12),
                EntityPickerField(
                  label: 'Humidity',
                  required: true,
                  value: _humidity,
                  candidates: discovery.candidatesForHumidity(_entities),
                  all: _entities,
                  onChanged: (v) => setState(() => _humidity = v),
                ),
                const SizedBox(height: 12),
                EntityPickerField(
                  label: 'VPD',
                  helper:
                      'Optional. VPD is recomputed from temperature and humidity; this is only a fallback.',
                  value: _vpd,
                  candidates: discovery.candidatesForVpd(_entities),
                  all: _entities,
                  onChanged: (v) => setState(() => _vpd = v),
                ),
                const SizedBox(height: 12),
                EntityPickerField(
                  label: 'Soil moisture',
                  helper: 'Optional.',
                  value: _soil,
                  candidates: discovery.candidatesForSoilMoisture(_entities),
                  all: _entities,
                  onChanged: (v) => setState(() => _soil = v),
                ),
                const SizedBox(height: 20),
                StageTargetFields(stages: _stages),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : (isEditing ? 'Save changes' : 'Add grow space'),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the grow space a name.')),
      );
      return;
    }
    for (final s in _stages) {
      for (final pair in [
        (s.tempMinF, s.tempMaxF),
        (s.humidityMinPct, s.humidityMaxPct),
        (s.vpdMinKpa, s.vpdMaxKpa),
      ]) {
        if (pair.$1 != null && pair.$2 != null && pair.$1! >= pair.$2!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${TomatoStageBands.labelFor(s.stageKey)}: min must be below max.',
              ),
            ),
          );
          return;
        }
      }
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(growSpacesRepositoryProvider);
      var id = widget.growSpaceId;
      if (id == null) {
        id = await repo.create(
          name: name,
          tempEntityId: _temp,
          humidityEntityId: _humidity,
          vpdEntityId: _vpd,
          soilMoistureEntityId: _soil,
        );
      } else {
        await repo.update(
          id: id,
          name: name,
          tempEntityId: _temp,
          humidityEntityId: _humidity,
          vpdEntityId: _vpd,
          soilMoistureEntityId: _soil,
        );
      }
      await repo.replaceStageTargets(
        growSpaceId: id,
        drafts: [
          for (final s in _stages)
            GrowSpaceStageTargetDraft(
              stageKey: s.stageKey,
              tempMinF: s.tempMinF,
              tempMaxF: s.tempMaxF,
              humidityMinPct: s.humidityMinPct,
              humidityMaxPct: s.humidityMaxPct,
              vpdMinKpa: s.vpdMinKpa,
              vpdMaxKpa: s.vpdMaxKpa,
            ),
        ],
      );
      if (mounted) context.pop();
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.growSpaceId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this grow space?'),
        content: const Text(
          'Plants assigned to it fall back to the default grow space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(growSpacesRepositoryProvider).delete(id);
    await ref.read(environmentSnapshotsDaoProvider).deleteForGrowSpace(id);
    if (mounted) context.pop();
  }
}
