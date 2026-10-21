import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/experience_section.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

Widget _experience(AppLocale locale) => SingleChildScrollView(
  child: ExperienceSection(
    roles: FakePortfolioRepository.contentFor(locale).roles,
  ),
);

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('lists Pulsati, Tecadi, Zirkon Labs and Philips in order', (
    tester,
  ) async {
    await tester.pumpLs(_experience(AppLocale.en));

    final tops = [
      for (final company in ['Pulsati', 'Tecadi', 'Zirkon Labs', 'Philips'])
        tester.getTopLeft(find.text(company)).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(tops.toSet(), hasLength(4));
  });

  testWidgets('shows the heading, the range and every role detail', (
    tester,
  ) async {
    final roles = FakePortfolioRepository.contentFor(AppLocale.en).roles;
    await tester.pumpLs(_experience(AppLocale.en));

    expect(find.text('Experience'), findsOne);
    expect(find.text('2021 — NOW'), findsOne);
    for (final role in roles) {
      expect(find.text(role.title), findsOne);
      expect(find.text(role.summary), findsOne);
    }
  });

  testWidgets('only the current role renders its period in the accent', (
    tester,
  ) async {
    await tester.pumpLs(_experience(AppLocale.en));

    expect(_color(tester, 'Mar 2025 — Now'), LsColors.dark.accent);
    for (final period in [
      'Nov 2024 — Mar 2025',
      'Jul 2023 — Nov 2024',
      'Dec 2021 — Apr 2023',
    ]) {
      expect(_color(tester, period), LsColors.dark.fg3);
    }
  });

  testWidgets('gives the header Experience link its scroll target', (
    tester,
  ) async {
    await tester.pumpLs(_experience(AppLocale.en));

    expect(SectionId.experience.key.currentContext, isNotNull);
  });

  testWidgets('the heading is a semantic header', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_experience(AppLocale.en));

    expect(
      tester.getSemantics(find.text('Experience')),
      isSemantics(label: 'Experience', isHeader: true),
    );
    handle.dispose();
  });

  for (final locale in AppLocale.values) {
    for (final width in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('lays out without overflow at ${width.toInt()} px in '
          '${locale.name}', (tester) async {
        await tester.pumpLs(
          _experience(locale),
          width: width,
          height: 740,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
