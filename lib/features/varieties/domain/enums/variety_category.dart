enum VarietyCategory {
  cherry('cherry', 'Cherry'),
  grape('grape', 'Grape'),
  paste('paste', 'Paste'),
  slicer('slicer', 'Slicer'),
  beefsteak('beefsteak', 'Beefsteak'),
  heirloom('heirloom', 'Heirloom');

  const VarietyCategory(this.storageValue, this.displayName);

  final String storageValue;
  final String displayName;

  static VarietyCategory fromStorage(String? value) {
    for (final category in values) {
      if (category.storageValue == value || category.name == value) {
        return category;
      }
    }
    return VarietyCategory.slicer;
  }
}
