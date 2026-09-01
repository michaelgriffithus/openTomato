import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RuntimePackageIdentity {
  const RuntimePackageIdentity({required this.version, required this.build});

  final String version;
  final String build;
}

final runtimePackageIdentityProvider = FutureProvider<RuntimePackageIdentity>((
  ref,
) async {
  final package = await PackageInfo.fromPlatform();
  return RuntimePackageIdentity(
    version: package.version,
    build: package.buildNumber,
  );
});
