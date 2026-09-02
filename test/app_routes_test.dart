import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:open_tomato/app.dart';

/// Screens outside the tab shell (plant detail, settings) push journal routes.
/// A location that resolves inside the StatefulShellRoute cannot be pushed
/// from there: go_router rebuilds the shell page with the same key and the
/// navigator asserts. These routes must therefore resolve without a shell.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  bool usesShell(String location) {
    final match = appRouter.configuration.findMatch(Uri.parse(location));
    expect(match.error, isNull, reason: location);
    expect(match.matches, isNotEmpty, reason: location);
    return match.matches.any((m) => m is ShellRouteMatch);
  }

  test('journal entry routes resolve outside the shell', () {
    expect(usesShell('/timeline/new?plantId=1'), isFalse);
    expect(usesShell('/timeline/edit/3'), isFalse);
    expect(usesShell('/timeline/3'), isFalse);
  });

  test('tab routes still resolve inside the shell', () {
    expect(usesShell('/timeline'), isTrue);
    expect(usesShell('/timeline/tasks'), isTrue);
    expect(usesShell('/plants'), isTrue);
  });
}
