import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TheArchitectApp());
    expect(find.byType(TheArchitectApp), findsOneWidget);
  });
}
