import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_paths.dart';
import '../../../../core/widgets/app_page_title.dart';
import '../../../../core/widgets/glass_date_time_picker.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../plants/domain/models/plant_model.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../../data/controllers/journal_entry_controller.dart';
import '../../data/models/journal_entry_with_details.dart';
import '../../domain/enums/entry_type.dart';
import '../../domain/services/journal_capture_validation.dart';
import '../widgets/journal_form_photo_picking.dart';
import '../widgets/journal_form_sections.dart';
import '../widgets/photo_thumbnail_grid.dart';
import '../widgets/plant_selector_chip.dart';

class JournalEntryFormScreen extends ConsumerStatefulWidget {
  /// Null creates an entry; non-null edits it.
  final int? entryId;
  final EntryType? initialType;
  final int? initialPlantId;
  final String? initialTitle;
  final int? completesTodoId;

  const JournalEntryFormScreen({
    super.key,
    this.entryId,
    this.initialType,
    this.initialPlantId,
    this.initialTitle,
    this.completesTodoId,
  });

  @override
  ConsumerState<JournalEntryFormScreen> createState() =>
      _JournalEntryFormScreenState();
}

class _JournalEntryFormScreenState extends ConsumerState<JournalEntryFormScreen>
    with JournalFormPhotoPicking {
  final _content = TextEditingController();
  final _tempF = TextEditingController();
  final _humidity = TextEditingController();
  final _vpd = TextEditingController();
  final _soil = TextEditingController();
  final _nutrientNotes = TextEditingController();
  final List<NutrientRowControllers> _nutrientRows = [];
  @override
  final List<String> newImagePaths = [];
  @override
  final List<int> photoIdsToDelete = [];
  @override
  List<JournalPhotoModel> existingPhotos = [];
  List<PlantModel> _selectedPlants = [];

  late EntryType _type = widget.initialType ?? EntryType.note;
  DateTime _timestamp = DateTime.now();
  DateTime? _createdAt;
  bool _watered = false;
  bool _saving = false;
  bool _fetching = false;
  String? _readingStatus;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) _content.text = widget.initialTitle!;
    if (widget.entryId != null) {
      _loadEntry();
    } else if (widget.initialPlantId != null) {
      _loadPlant(widget.initialPlantId!);
    }
    if (_type == EntryType.fertilizing) {
      _nutrientRows.add(NutrientRowControllers());
    }
  }

  Future<void> _loadEntry() async {
    final data = await ref
        .read(journalEntryControllerProvider)
        .loadEntry(widget.entryId!);
    if (data == null || !mounted) return;
    setState(() {
      _type = data.type;
      _timestamp = data.timestamp;
      _createdAt = data.createdAt;
      _content.text = data.content;
      _selectedPlants = data.plants;
      existingPhotos = data.photos;
      _tempF.text = data.tempF?.toStringAsFixed(1) ?? '';
      _humidity.text = data.humidityPct?.toStringAsFixed(0) ?? '';
      _vpd.text = data.vpdKpa?.toStringAsFixed(2) ?? '';
      _soil.text = data.soilMoisturePct?.toStringAsFixed(0) ?? '';
      _watered = data.watered;
      _nutrientNotes.text = data.nutrients;
      for (final row in data.nutrientRows) {
        _nutrientRows.add(
          NutrientRowControllers(
            productName: row.productName,
            amountText: row.amount,
          ),
        );
      }
    });
  }

  Future<void> _loadPlant(int plantId) async {
    final plant =
        await ref.read(journalEntryControllerProvider).loadPlant(plantId);
    if (plant != null && mounted) setState(() => _selectedPlants = [plant]);
  }

  @override
  void dispose() {
    _content.dispose();
    _tempF.dispose();
    _humidity.dispose();
    _vpd.dispose();
    _soil.dispose();
    _nutrientNotes.dispose();
    for (final row in _nutrientRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isEditing = widget.entryId != null;
    final photoPaths = [
      for (final photo in existingPhotos)
        if (!photoIdsToDelete.contains(photo.id))
          AppPaths.resolveDocumentPath(photo.thumbnailPath),
      ...newImagePaths,
    ];
    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(pageName: isEditing ? 'Edit entry' : 'New entry'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          DropdownButtonFormField<EntryType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'What happened',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final type in EntryType.selectable)
                DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 18),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _type = value;
                if (value == EntryType.fertilizing && _nutrientRows.isEmpty) {
                  _nutrientRows.add(NutrientRowControllers());
                }
              });
            },
          ),
          const SizedBox(height: 12),
          GlassDateTimePicker(
            value: _timestamp,
            labelText: 'When',
            mode: DateTimePickerMode.dateAndTime,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 1)),
            onChanged: (picked) => setState(() => _timestamp = picked),
          ),
          const SizedBox(height: 12),
          PlantSelectorChips(
            selectedPlants: _selectedPlants,
            onTap: _pickPlants,
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _content,
            labelText: 'Notes',
            hintText: 'What did you see or do?',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          if (_type == EntryType.fertilizing) ...[
            NutrientRowsSection(
              rows: _nutrientRows,
              onAdd: () =>
                  setState(() => _nutrientRows.add(NutrientRowControllers())),
              onRemove: (i) =>
                  setState(() => _nutrientRows.removeAt(i).dispose()),
            ),
            const SizedBox(height: 12),
          ],
          if (_type != EntryType.watering)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Watered as well'),
              value: _watered,
              onChanged: (v) => setState(() => _watered = v),
            ),
          ReadingsSection(
            tempF: _tempF,
            humidityPct: _humidity,
            vpdKpa: _vpd,
            soilMoisturePct: _soil,
            fetching: _fetching,
            statusLine: _readingStatus,
            onUseCurrent: _useCurrentReading,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: pickFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: pickFromLibrary,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Library'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PhotoThumbnailGrid(photoPaths: photoPaths, onDelete: removePhoto),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Saving…' : (isEditing ? 'Save changes' : 'Save entry'),
            ),
          ),
          if (widget.completesTodoId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Saving marks the task as done.',
                style: TextStyle(color: palette.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickPlants() async {
    final available = ref.read(activePlantsProvider).valueOrNull ?? const [];
    final ids = await showDialog<List<int>>(
      context: context,
      builder: (_) => PlantSelectorDialog(
        availablePlants: [for (final p in available) p.plant],
        initialSelectedIds: [for (final p in _selectedPlants) p.id],
      ),
    );
    if (ids == null) return;
    setState(() {
      _selectedPlants = [
        for (final p in available)
          if (ids.contains(p.plant.id)) p.plant,
      ];
    });
  }

  Future<void> _useCurrentReading() async {
    setState(() => _fetching = true);
    try {
      final reading =
          await ref.read(journalEntryControllerProvider).currentReading(
        plantIds: [for (final p in _selectedPlants) p.id],
      );
      if (!mounted) return;
      if (reading == null) {
        setState(
          () =>
              _readingStatus = 'No readings recorded for this grow space yet.',
        );
        return;
      }
      setState(() {
        if (reading.tempF != null) {
          _tempF.text = reading.tempF!.toStringAsFixed(1);
        }
        if (reading.humidityPct != null) {
          _humidity.text = reading.humidityPct!.toStringAsFixed(0);
        }
        if (reading.vpdKpa != null) {
          _vpd.text = reading.vpdKpa!.toStringAsFixed(2);
        }
        if (reading.soilMoisturePct != null) {
          _soil.text = reading.soilMoisturePct!.toStringAsFixed(0);
        }
        final age = DateTime.now().difference(reading.timestamp).inMinutes;
        _readingStatus = reading.isFresh
            ? 'From Home Assistant, $age min ago.'
            : 'Last reading is ${(age / 60).round()} h old; check it is still true.';
      });
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _save() async {
    final validation = validateJournalCapture(
      JournalCaptureValidationInput(
        type: _type,
        content: _content.text,
        photoCount: existingPhotos.length -
            photoIdsToDelete.length +
            newImagePaths.length,
        nutrientProductNames: [for (final r in _nutrientRows) r.name.text],
        hasReadings: _tempF.text.isNotEmpty ||
            _humidity.text.isNotEmpty ||
            _soil.text.isNotEmpty,
      ),
    );
    if (!validation.isValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validation.message!)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(journalEntryControllerProvider).save(
            JournalEntrySaveRequest(
              entryId: widget.entryId,
              type: _type,
              timestamp: _timestamp,
              content: _content.text,
              plantIds: [for (final p in _selectedPlants) p.id],
              newImagePaths: newImagePaths,
              photoIdsToDelete: photoIdsToDelete,
              tempF: double.tryParse(_tempF.text.trim()),
              humidityPct: double.tryParse(_humidity.text.trim()),
              vpdKpa: double.tryParse(_vpd.text.trim()),
              soilMoisturePct: double.tryParse(_soil.text.trim()),
              watered: _watered,
              nutrients: _nutrientNotes.text,
              nutrientRows: [
                for (final r in _nutrientRows)
                  NutrientLineItemModel(
                    productName: r.name.text,
                    amount: r.amount.text,
                  ),
              ],
              createdAt: _createdAt,
              completesTodoId: widget.completesTodoId,
            ),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? e.userMessage
                  : 'Could not save the entry: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
