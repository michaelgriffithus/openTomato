import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/core/database/database.dart';

/// A build's identity says which database shape it expects. When the two
/// drift you cannot tell from a crash report which migration a device ran.
void main() {
  test('pubspec build number equals AppDatabase.schemaVersion', () async {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*\S+\+(\d+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec version must carry +build');
    final buildNumber = int.parse(match!.group(1)!);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(buildNumber, db.schemaVersion);
  });
}
