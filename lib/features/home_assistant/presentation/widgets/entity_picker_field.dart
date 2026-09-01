import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/ha_discovered_entity.dart';
import '../../data/services/ha_entity_discovery_service.dart';

/// A slot in the grow space editor: shows the chosen entity, opens a
/// searchable picker over discovered candidates, and warns when the entity
/// looks like something other than air in a grow space.
class EntityPickerField extends StatelessWidget {
  final String label;
  final String? value;
  final List<HADiscoveredEntity> candidates;
  final List<HADiscoveredEntity> all;
  final String? helper;
  final bool required;
  final ValueChanged<String?> onChanged;

  const EntityPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.candidates,
    required this.all,
    required this.onChanged,
    this.helper,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final current = value;
    final match = current == null
        ? null
        : all.where((e) => e.entityId == current).firstOrNull;
    final suspicious = current != null &&
        HAEntityDiscoveryService.looksSuspiciousForAir(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: required ? '$label (required)' : label,
              helperText: helper,
              border: const OutlineInputBorder(),
              suffixIcon: current == null
                  ? const Icon(Icons.search)
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => onChanged(null),
                    ),
            ),
            child: Text(
              current == null
                  ? 'Tap to choose'
                  : match == null
                      ? current
                      : '${match.displayLabel} · ${match.state}',
              style: current == null
                  ? AppTextStyles.bodyMedium
                      .copyWith(color: palette.textSecondary)
                  : AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (suspicious)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: palette.statusHighText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This looks like a device sensor, not the air in a grow space. '
                    'Check the value before saving.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: palette.statusHighText),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EntityPickerSheet(
        label: label,
        candidates: candidates,
        all: all,
        current: value,
      ),
    );
    if (picked != null) onChanged(picked.isEmpty ? null : picked);
  }
}

class _EntityPickerSheet extends StatefulWidget {
  final String label;
  final List<HADiscoveredEntity> candidates;
  final List<HADiscoveredEntity> all;
  final String? current;

  const _EntityPickerSheet({
    required this.label,
    required this.candidates,
    required this.all,
    required this.current,
  });

  @override
  State<_EntityPickerSheet> createState() => _EntityPickerSheetState();
}

class _EntityPickerSheetState extends State<_EntityPickerSheet> {
  final _search = TextEditingController();
  bool _showAll = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final query = _search.text.trim().toLowerCase();
    final source = _showAll ? widget.all : widget.candidates;
    final items = query.isEmpty
        ? source
        : source.where((e) => e.searchText.contains(query)).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Text(widget.label, style: AppTextStyles.h3),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or entity id',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Show every sensor'),
                  value: _showAll,
                  onChanged: (v) => setState(() => _showAll = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No matching sensors.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: palette.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final e = items[index];
                      return ListTile(
                        title: Text(e.displayLabel),
                        subtitle: Text(
                          '${e.entityId} · ${e.state}${e.unit == null ? '' : ' ${e.unit}'}',
                        ),
                        selected: e.entityId == widget.current,
                        onTap: () => Navigator.of(context).pop(e.entityId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
