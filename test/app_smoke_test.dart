import 'package:flutter_test/flutter_test.dart';
import 'package:open_tomato/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const MainApp());
    expect(find.byType(MainApp), findsOneWidget);
  });
}
