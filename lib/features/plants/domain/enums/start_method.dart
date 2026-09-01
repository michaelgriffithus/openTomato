enum StartMethod {
  seed('seed', 'From seed'),
  transplant('transplant', 'Transplant'),
  cutting('cutting', 'Cutting');

  const StartMethod(this.storageValue, this.displayName);

  final String storageValue;
  final String displayName;

  static StartMethod fromStorage(String? value) {
    for (final method in values) {
      if (method.storageValue == value || method.name == value) return method;
    }
    return StartMethod.seed;
  }
}
