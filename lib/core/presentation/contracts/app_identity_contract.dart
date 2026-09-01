class AppIdentityContract {
  const AppIdentityContract({
    required this.productLabel,
    required this.versionLabel,
  });

  final String productLabel;
  final String versionLabel;

  static const resolving = AppIdentityContract(
    productLabel: 'OpenTomato',
    versionLabel: 'Version …',
  );
}
