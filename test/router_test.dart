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

  testWidgets('switching language keeps the scroll offset', (tester) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(700);
    await tester.pump();

    tester
        .element(find.byType(Scaffold))
        .read<LocaleCubit>()
        .select(AppLocale.pt);
    await tester.pumpAndSettle();

    final after = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(after.position.pixels, 700);
    expect(after.context.read<LocaleCubit>().state, AppLocale.pt);
  });
}
