import 'package:flutter_test/flutter_test.dart';
import 'package:parakh/main.dart';

void main() {
  testWidgets('PARAKH smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ParakhApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(ParakhApp), findsOneWidget);
  });
}
