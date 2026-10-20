import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/app.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/presentation/cubits/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'helpers/fake_portfolio_repository.dart';

void main() {
  testWidgets('shows the header and the hero from the loaded content', (
    tester,
  ) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Lucas\nSchmidt'), findsOneWidget);
    expect(find.text('Lucas Schmidt'), findsOneWidget);
    expect(find.text('CURRENTLY'), findsOneWidget);
  });

  testWidgets('shows the name and a mail link when the content fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      App(repository: FakePortfolioRepository(failing: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lucas\nSchmidt'), findsOneWidget);
    final mail = tester.widget<LsButton>(find.byType(LsButton));
    expect(mail.href, SiteConfig.mailto);
  });

  testWidgets('the theme button toggles the theme', (tester) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    final cubit = tester.element(find.byType(Scaffold)).read<ThemeCubit>();
    expect(cubit.state, ThemeMode.dark);

    await tester.tap(find.byIcon(Icons.contrast));
    await tester.pumpAndSettle();

    expect(cubit.state, ThemeMode.light);
  });
}
