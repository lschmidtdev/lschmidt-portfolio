import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/app.dart';

void main() {
  testWidgets('shows the name', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Lucas Schmidt'), findsOneWidget);
  });
}
