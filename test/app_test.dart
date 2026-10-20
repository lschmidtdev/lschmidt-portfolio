import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/app.dart';

import 'helpers/fake_portfolio_repository.dart';

void main() {
  testWidgets('shows the name from the loaded content', (tester) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Lucas Schmidt'), findsOneWidget);
  });

  testWidgets('shows the name when the content fails to load', (tester) async {
    await tester.pumpWidget(
      App(repository: FakePortfolioRepository(failing: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lucas Schmidt'), findsOneWidget);
  });
}
