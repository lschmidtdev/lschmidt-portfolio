import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_header.dart';

import '../../helpers/pump_ls.dart';

Widget _page({
  AppLocale locale = AppLocale.en,
  ValueChanged<AppLocale>? onLocale,
  VoidCallback? onTheme,
}) => SingleChildScrollView(
  child: Column(
    children: [
      SiteHeader(
        locale: locale,
        onLocaleSelected: onLocale ?? (_) {},
        onToggleTheme: onTheme ?? () {},
      ),
      const SizedBox(height: 1500),
      const SectionShell(id: SectionId.work, child: SizedBox(height: 100)),
      const SizedBox(height: 1500),
      const SectionShell(id: SectionId.contact, child: SizedBox(height: 100)),
    ],
  ),
);

void main() {
  testWidgets('shows the brand and the four nav links in English', (
    tester,
  ) async {
    await tester.pumpLs(_page());

    expect(find.text('Lucas Schmidt'), findsOneWidget);
    expect(find.text('LS'), findsOneWidget);
    for (final label in ['WORK', 'EXPERIENCE', 'SKILLS', 'CONTACT']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows the nav links in Portuguese', (tester) async {
    await tester.pumpLs(_page(locale: AppLocale.pt), locale: AppLocale.pt);

    for (final label in ['TRABALHO', 'EXPERIÊNCIA', 'HABILIDADES', 'CONTATO']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('nav links are links and scroll to their section', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_page(), reducedMotion: true);
    expect(
      tester.getSemantics(find.text('WORK')),
      isSemantics(label: 'Work', isLink: true, hasTapAction: true),
    );

    await tester.tap(find.text('CONTACT'));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(1500));
    handle.dispose();
  });

  testWidgets('the selected language is marked and the other one switches', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final picked = <AppLocale>[];
    await tester.pumpLs(_page(onLocale: picked.add));

    expect(
      tester.getSemantics(find.text('EN')),
      isSemantics(label: 'English', isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('PT')),
      isSemantics(label: 'Português', isButton: true, isSelected: false),
    );

    await tester.tap(find.text('PT'));

    expect(picked, [AppLocale.pt]);
    handle.dispose();
  });

  testWidgets('the icon-only theme button has an accessible name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var toggles = 0;
    await tester.pumpLs(_page(onTheme: () => toggles++));

    final button = find.bySemanticsLabel('Toggle light or dark theme');
    expect(button, findsOneWidget);
    await tester.tap(button);

    expect(toggles, 1);
    handle.dispose();
  });

  testWidgets('the theme button is labelled in Portuguese', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_page(locale: AppLocale.pt), locale: AppLocale.pt);

    expect(find.bySemanticsLabel('Alternar tema claro ou escuro'), findsOne);
    handle.dispose();
  });

  testWidgets('every control keeps a 48 px target', (tester) async {
    await tester.pumpLs(_page());

    for (final text in [
      'WORK',
      'EXPERIENCE',
      'SKILLS',
      'CONTACT',
      'EN',
      'PT',
    ]) {
      final target = find.ancestor(
        of: find.text(text),
        matching: find.byType(GestureDetector),
      );
      final size = tester.getSize(target.first);
      expect(size.height, greaterThanOrEqualTo(48), reason: text);
      expect(size.width, greaterThanOrEqualTo(48), reason: text);
    }
    final theme = find.bySemanticsLabel('Toggle light or dark theme');
    expect(tester.getSize(theme).height, greaterThanOrEqualTo(48));
  });

  for (final locale in AppLocale.values) {
    testWidgets('lays out at 360 px in ${locale.name} without overflow', (
      tester,
    ) async {
      await tester.pumpLs(
        _page(locale: locale),
        width: 360,
        height: 740,
        locale: locale,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
