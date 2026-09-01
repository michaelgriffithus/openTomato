import 'package:flutter/material.dart';

import '../enums/entry_type.dart';

/// Display properties for entry types.
class EventTypeHelper {
  static IconData getIcon(EntryType type) => type.icon;

  static Color getColor(EntryType type) => switch (type) {
        EntryType.watering => const Color(0xFF2196F3),
        EntryType.fertilizing => const Color(0xFF66BB6A),
        EntryType.pruning => const Color(0xFF9C27B0),
        EntryType.staking => const Color(0xFF8B7355),
        EntryType.transplanting => const Color(0xFF6D4C41),
        EntryType.pest => const Color(0xFFEF5350),
        EntryType.disease => const Color(0xFFD84315),
        EntryType.flowering => const Color(0xFFE8C547),
        EntryType.harvest => const Color(0xFFD64B3C),
        EntryType.photo => const Color(0xFF26A69A),
        EntryType.stageChange => const Color(0xFFFFA726),
        EntryType.inspect => const Color(0xFF8E7CC3),
        EntryType.note => const Color(0xFF94A3B8),
      };

  static String getLabel(EntryType type) => type.displayName;

  /// Past-tense verb for titles such as "Sungold watered".
  static String getVerb(EntryType type) => switch (type) {
        EntryType.watering => 'watered',
        EntryType.fertilizing => 'fed',
        EntryType.pruning => 'pruned',
        EntryType.staking => 'staked',
        EntryType.transplanting => 'transplanted',
        EntryType.pest => 'pest noted',
        EntryType.disease => 'disease noted',
        EntryType.flowering => 'started flowering',
        EntryType.harvest => 'harvested',
        EntryType.photo => 'photographed',
        EntryType.stageChange => 'stage changed',
        EntryType.inspect => 'inspected',
        EntryType.note => 'note added',
      };
}
