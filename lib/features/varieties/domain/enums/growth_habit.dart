enum GrowthHabit {
  determinate(
    'determinate',
    'Determinate',
    'Bush type; sets most fruit at once.',
  ),
  indeterminate(
    'indeterminate',
    'Indeterminate',
    'Vining; keeps growing and fruiting until frost.',
  ),
  semiDeterminate(
    'semi_determinate',
    'Semi-determinate',
    'Compact vine with a longer harvest than a bush.',
  ),
  dwarf('dwarf', 'Dwarf', 'Very compact; happy in a small container.');

  const GrowthHabit(this.storageValue, this.displayName, this.description);

  final String storageValue;
  final String displayName;
  final String description;

  static GrowthHabit fromStorage(String? value) {
    for (final habit in values) {
      if (habit.storageValue == value || habit.name == value) return habit;
    }
    return GrowthHabit.indeterminate;
  }
}
