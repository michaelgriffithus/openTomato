import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/providers/database_provider.dart';
import 'core/utils/app_paths.dart';
import 'features/home_assistant/presentation/widgets/ha_polling_bootstrap.dart';
import 'features/varieties/data/seed_data/variety_seeds.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
  runApp(
    const ProviderScope(
      child: HaPollingBootstrap(child: OpenTomatoApp()),
    ),
  );
}

Future<void> _bootstrap() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    AppPaths.init(appDir.path);
    final container = ProviderContainer();
    try {
      await VarietySeeds.seedDatabase(container.read(databaseProvider));
    } finally {
      container.dispose();
    }
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'main',
        context: ErrorDescription('while bootstrapping app services'),
      ),
    );
  }
}
