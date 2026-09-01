/// Returns the median of [values], or null when the list is empty.
double? median(List<double> values) {
  if (values.isEmpty) {
    return null;
  }
  final sorted = List<double>.from(values)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) {
    return sorted[mid];
  }
  return (sorted[mid - 1] + sorted[mid]) / 2.0;
}
