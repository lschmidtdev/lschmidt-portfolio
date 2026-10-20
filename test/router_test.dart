import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/app.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/cubits/locale_cubit.dart';
import 'package:lschmidt_portfolio/routes.dart';

import 'helpers/fake_portfolio_repository.dart';

void main() {
  test('the two routes stay; everything else goes to English', () {
    expect(redirectFor('/'), isNull);
    expect(redirectFor('/pt'), isNull);
    expect(redirectFor('/pt/'), '/pt');
    expect(redirectFor('/PT'), '/');
    expect(redirectFor('/nope'), '/');
    expect(redirectFor(''), '/');
  });

  testWidgets('/ is English and /pt is Portuguese', (tester) async {
    await tester.pumpWidget(
      App(initialLocation: '/', repository: FakePortfolioRepository()),
    );
    await tester.pumpAndSettle();
    final english = tester.element(find.byType(Scaffold));
    expect(english.read<LocaleCubit>().state, AppLocale.en);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      App(initialLocation: '/pt', repository: FakePortfolioRepository()),
    );
    await tester.pumpAndSettle();
    final portuguese = tester.element(find.byType(Scaffold));
    expect(portuguese.read<LocaleCubit>().state, AppLocale.pt);
  });

  testWidgets('switching language keeps the scroll offset and the content', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 500);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(300));
    scrollable.position.jumpTo(300);
    await tester.pump();

    tester
        .element(find.byType(Scaffold))
        .read<LocaleCubit>()
        .select(AppLocale.pt);
    await tester.pump();

    expect(find.text('Lucas\nSchmidt'), findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      300,
    );

    await tester.pumpAndSettle();

    final after = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(after.position.pixels, 300);
    expect(after.context.read<LocaleCubit>().state, AppLocale.pt);
    expect(find.text('ATUALMENTE'), findsOneWidget);
    expect(
      find.text('Engenheiro Mobile — Flutter'.toUpperCase()),
      findsOneWidget,
    );
  });
}
