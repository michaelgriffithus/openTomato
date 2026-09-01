import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/theme/app_theme.dart';
import 'package:open_tomato/features/environment/domain/environment_range_evaluator.dart';
import 'package:open_tomato/features/environment/presentation/providers/environment_providers.dart';
import 'package:open_tomato/features/today/presentation/contracts/today_contract.dart';
import 'package:open_tomato/features/today/presentation/screens/today_screen.dart';

class _NoopActions implements TodayActions {
  @override
  void addEntry() {}
  @override
  void addPlant() {}
  @override
  void connectHomeAssistant() {}
  @override
  void openPlant(int id) {}
  @override
  void openSettings() {}
  @override
  void selectGrowSpace(String id) {}
  @override
  void selectTraceMetric(EnvironmentMetric metric) {}
  @override
  void selectWindow(bool isDay) {}
}

void main() {
  testWidgets('Today renders the unconfigured state from a contract',
      (tester) async {
    const contract = TodayContract(
      state: TodayState.unconfigured,
      growSpaceName: 'My grow space',
      growSpaceId: 'default',
      growSpaceChoices: [],
      freshnessLabel: 'No readings yet',
      freshnessTone: StatusTone.muted,
      stageLabel: 'No active plant',
      bandsOverridden: false,
      readings: [],
      focusLine: 'Connect Home Assistant to see readings.',
      selectedWindow: ReadingWindow.day,
      timeInRange: [],
      trace: null,
      traceMetric: EnvironmentMetric.vpd,
      plants: [],
      backfillRunning: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: TodayView(contract: contract, actions: _NoopActions()),
      ),
    );
    expect(find.text('Connect Home Assistant'), findsOneWidget);
    expect(find.text('Add a plant'), findsOneWidget);
  });
}
