import 'package:flutter_test/flutter_test.dart';
import 'package:onlymen/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OnlyMenApp());
    expect(find.byType(OnlyMenApp), findsOneWidget);
  });
}