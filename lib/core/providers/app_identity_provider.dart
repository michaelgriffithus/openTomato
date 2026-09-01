import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/contracts/app_identity_contract.dart';
import 'runtime_package_identity_provider.dart';

final appIdentityContractProvider = Provider<AppIdentityContract>((ref) {
  final package = ref.watch(runtimePackageIdentityProvider);
  final runtime = package.valueOrNull;
  final versionLabel = runtime == null
      ? 'Version …'
      : 'Version ${runtime.version} (${runtime.build})';
  return AppIdentityContract(
    productLabel: 'OpenTomato',
    versionLabel: versionLabel,
  );
});
