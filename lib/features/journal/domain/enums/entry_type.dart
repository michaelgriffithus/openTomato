import 'package:flutter/material.dart';

enum EntryType {
  note('note', 'Note', Icons.notes_outlined),
  watering('watering', 'Watering', Icons.water_drop_outlined),
  fertilizing('fertilizing', 'Fertilizing', Icons.science_outlined),
  pruning('pruning', 'Pruning', Icons.content_cut),
  staking('staking', 'Staking', Icons.vertical_align_top),
  transplanting('transplanting', 'Transplanting', Icons.move_down),
  pest('pest', 'Pest', Icons.bug_report_outlined),
  disease('disease', 'Disease', Icons.coronavirus_outlined),
  flowering('flowering', 'Flowering', Icons.local_florist_outlined),
  harvest('harvest', 'Harvest', Icons.shopping_basket_outlined),
  photo('photo', 'Photo', Icons.photo_camera_outlined),
  stageChange('stage_change', 'Stage change', Icons.timeline),
  inspect('inspect', 'Inspection', Icons.search);

  const EntryType(this.storageValue, this.displayName, this.icon);

  final String storageValue;
  final String displayName;
  final IconData icon;

  /// Types a grower picks in the entry form (system-written ones excluded).
  static List<EntryType> get selectable =>
      values.where((t) => t != stageChange).toList(growable: false);

  static EntryType fromStorage(String? value) {
    for (final type in values) {
      if (type.storageValue == value || type.name == value) return type;
    }
    return EntryType.note;
  }
}
