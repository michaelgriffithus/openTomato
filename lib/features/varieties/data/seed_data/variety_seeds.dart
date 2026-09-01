import 'package:drift/drift.dart' as drift;

import '../../../../core/database/database.dart';
import '../../domain/enums/growth_habit.dart';
import '../../domain/enums/variety_category.dart';

class VarietySeed {
  final String name;
  final GrowthHabit habit;
  final VarietyCategory category;
  final int daysToMaturity;
  final String notes;

  const VarietySeed(
    this.name,
    this.habit,
    this.category,
    this.daysToMaturity,
    this.notes,
  );
}

/// Well-known tomato varieties pre-loaded on first run. Days to maturity are
/// counted from transplant, as seed packets do.
class VarietySeeds {
  static const List<VarietySeed> seeds = [
    // Heirlooms
    VarietySeed(
      'Brandywine',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      85,
      'Large pink beefsteak; potato-leaf foliage; classic flavour.',
    ),
    VarietySeed(
      'Cherokee Purple',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      80,
      'Dusky purple-red; rich, smoky-sweet flavour.',
    ),
    VarietySeed(
      'Black Krim',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      80,
      'Dark red-brown with green shoulders; salty-sweet.',
    ),
    VarietySeed(
      'Green Zebra',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      75,
      'Green-striped, tangy; ripe when the stripes turn gold.',
    ),
    VarietySeed(
      'Mortgage Lifter',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      85,
      'Huge pink fruit, few seeds, mild and sweet.',
    ),
    VarietySeed(
      'Paul Robeson',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      78,
      'Black-red; earthy, complex flavour; tolerates cool nights.',
    ),
    VarietySeed(
      'Costoluto Genovese',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      78,
      'Deeply ribbed Italian slicer; great for sauce and slicing.',
    ),
    VarietySeed(
      'Yellow Pear',
      GrowthHabit.indeterminate,
      VarietyCategory.heirloom,
      75,
      'Small pear-shaped yellow fruit; very productive.',
    ),
    // Cherry and dwarf
    VarietySeed(
      'Sungold',
      GrowthHabit.indeterminate,
      VarietyCategory.cherry,
      57,
      'Orange cherry, very sweet; splits after heavy rain.',
    ),
    VarietySeed(
      'Sweet 100',
      GrowthHabit.indeterminate,
      VarietyCategory.cherry,
      65,
      'Long trusses of red cherries; very vigorous.',
    ),
    VarietySeed(
      'Supersweet 100',
      GrowthHabit.indeterminate,
      VarietyCategory.cherry,
      65,
      'Improved Sweet 100 with better disease resistance.',
    ),
    VarietySeed(
      'Black Cherry',
      GrowthHabit.indeterminate,
      VarietyCategory.cherry,
      65,
      'Dusky purple cherry with heirloom flavour.',
    ),
    VarietySeed(
      'Tiny Tim',
      GrowthHabit.dwarf,
      VarietyCategory.cherry,
      45,
      'Windowsill dwarf, about 30 cm tall.',
    ),
    VarietySeed(
      'Micro Tom',
      GrowthHabit.dwarf,
      VarietyCategory.cherry,
      50,
      'The smallest tomato plant; fine in a 10 cm pot.',
    ),
    VarietySeed(
      'Principe Borghese',
      GrowthHabit.determinate,
      VarietyCategory.cherry,
      75,
      'Italian sun-dried type; heavy set of small fruit.',
    ),
    // Grape
    VarietySeed(
      'Juliet',
      GrowthHabit.indeterminate,
      VarietyCategory.grape,
      60,
      'Crack-resistant red grape; keeps well on the vine.',
    ),
    VarietySeed(
      'Chocolate Sprinkles',
      GrowthHabit.indeterminate,
      VarietyCategory.grape,
      55,
      'Red-and-green striped grape; sweet and productive.',
    ),
    // Paste
    VarietySeed(
      'San Marzano',
      GrowthHabit.indeterminate,
      VarietyCategory.paste,
      80,
      'The classic Italian sauce tomato; meaty, few seeds.',
    ),
    VarietySeed(
      'Roma',
      GrowthHabit.determinate,
      VarietyCategory.paste,
      75,
      'Compact plum for sauce and canning.',
    ),
    VarietySeed(
      'Amish Paste',
      GrowthHabit.indeterminate,
      VarietyCategory.paste,
      85,
      'Large heirloom paste; good fresh as well.',
    ),
    // Slicers
    VarietySeed(
      'Early Girl',
      GrowthHabit.indeterminate,
      VarietyCategory.slicer,
      57,
      'Reliable early red slicer.',
    ),
    VarietySeed(
      'Bush Early Girl',
      GrowthHabit.determinate,
      VarietyCategory.slicer,
      54,
      'Compact form of Early Girl for containers.',
    ),
    VarietySeed(
      'Better Boy',
      GrowthHabit.indeterminate,
      VarietyCategory.slicer,
      75,
      'Big, smooth red slicer; very heavy yields.',
    ),
    VarietySeed(
      'Celebrity',
      GrowthHabit.semiDeterminate,
      VarietyCategory.slicer,
      70,
      'Disease-resistant workhorse; medium red fruit.',
    ),
    VarietySeed(
      'Rutgers',
      GrowthHabit.determinate,
      VarietyCategory.slicer,
      75,
      'Old-fashioned red slicer bred for flavour.',
    ),
    VarietySeed(
      'Stupice',
      GrowthHabit.indeterminate,
      VarietyCategory.slicer,
      55,
      'Very early; sets fruit in cool weather.',
    ),
    VarietySeed(
      'Glacier',
      GrowthHabit.determinate,
      VarietyCategory.slicer,
      56,
      'Extra-early; good for short seasons.',
    ),
    VarietySeed(
      'Mountain Merit',
      GrowthHabit.determinate,
      VarietyCategory.slicer,
      75,
      'Strong late-blight resistance; firm red fruit.',
    ),
    VarietySeed(
      'Defiant',
      GrowthHabit.determinate,
      VarietyCategory.slicer,
      70,
      'Late-blight resistant; medium red slicer.',
    ),
    VarietySeed(
      'Patio Princess',
      GrowthHabit.determinate,
      VarietyCategory.slicer,
      65,
      'Bred for pots; small plant, full-size flavour.',
    ),
    // Beefsteak
    VarietySeed(
      'Big Beef',
      GrowthHabit.indeterminate,
      VarietyCategory.beefsteak,
      73,
      'Large, smooth, reliable; wide disease resistance.',
    ),
    VarietySeed(
      'Beefsteak',
      GrowthHabit.indeterminate,
      VarietyCategory.beefsteak,
      85,
      'The classic huge red slicer; late.',
    ),
  ];

  static List<VarietiesCompanion> get companions => [
        for (final seed in seeds)
          VarietiesCompanion(
            name: drift.Value(seed.name),
            growthHabit: drift.Value(seed.habit.storageValue),
            category: drift.Value(seed.category.storageValue),
            daysToMaturity: drift.Value(seed.daysToMaturity),
            notes: drift.Value(seed.notes),
            userCreated: const drift.Value(false),
          ),
      ];

  /// Idempotent by name: inserts only the varieties that are missing, so a
  /// grower's edits and additions survive app updates.
  static Future<void> seedDatabase(AppDatabase db) async {
    final existing = await db.select(db.varieties).get();
    final names = existing.map((v) => v.name).toSet();
    final missing =
        companions.where((c) => !names.contains(c.name.value)).toList();
    if (missing.isEmpty) return;
    await db.batch((batch) {
      batch.insertAll(db.varieties, missing);
    });
  }
}
