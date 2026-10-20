import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/hero.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

final _now = DateTime(2026, 10, 20);

HeroSection _hero(AppLocale locale, {bool? cvAvailable}) {
  final content = FakePortfolioRepository.contentFor(locale);
  return cvAvailable == null
      ? HeroSection(
          profile: content.profile,
          currently: content.currently,
          locale: locale,
          now: _now,
        )
      : HeroSection(
          profile: content.profile,
          currently: content.currently,
          locale: locale,
          now: _now,
          cvAvailable: cvAvailable,
        );
}

Widget _page(HeroSection hero) => SingleChildScrollView(
  child: Column(
    children: [
      hero,
      const SizedBox(height: 1500),
      const SectionShell(id: SectionId.contact, child: SizedBox(height: 200)),
    ],
  ),
);

LsButton _button(WidgetTester tester, String label) => tester
    .widgetList<LsButton>(find.byType(LsButton))
    .firstWhere((button) => button.label == label);

void main() {
  testWidgets('shows the role, the name and the summary', (tester) async {
    final handle = tester.ensureSemantics();
    final content = FakePortfolioRepository.contentFor(AppLocale.en);
    await tester.pumpLs(_page(_hero(AppLocale.en)));

    expect(find.bySemanticsLabel('Mobile Engineer — Flutter'), findsOneWidget);
    expect(find.text('Lucas\nSchmidt'), findsOneWidget);
    expect(find.text(content.profile.summary), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Lucas\nSchmidt')),
      isSemantics(label: 'Lucas Schmidt', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('shows the Currently card beside the copy on desktop', (
    tester,
  ) async {
    await tester.pumpLs(_page(_hero(AppLocale.en)));

    final card = tester.getRect(find.text('CURRENTLY'));
    final name = tester.getRect(find.text('Lucas\nSchmidt'));
    expect(card.left, greaterThan(name.right));
  });

  testWidgets('stacks the Currently card under the copy on a phone', (
    tester,
  ) async {
    await tester.pumpLs(_page(_hero(AppLocale.en)), width: 390, height: 844);

    final card = tester.getRect(find.text('CURRENTLY'));
    final name = tester.getRect(find.text('Lucas\nSchmidt'));
    expect(card.top, greaterThan(name.bottom));
  });

  group('CV button', () {
    testWidgets('is absent while no CV is published', (tester) async {
      await tester.pumpLs(_page(_hero(AppLocale.en)));

      expect(find.text('Download CV (PDF)'), findsNothing);
      expect(find.text('Email me'), findsOneWidget);
    });

    testWidgets('links the English PDF on /', (tester) async {
      await tester.pumpLs(_page(_hero(AppLocale.en, cvAvailable: true)));

      expect(
        _button(tester, 'Download CV (PDF)').href.toString(),
        '/cv/lucas-schmidt-cv-en.pdf',
      );
    });

    testWidgets('links the Portuguese PDF on /pt', (tester) async {
      await tester.pumpLs(
        _page(_hero(AppLocale.pt, cvAvailable: true)),
        locale: AppLocale.pt,
      );

      expect(
        _button(tester, 'Baixar CV (PDF)').href.toString(),
        '/cv/lucas-schmidt-cv-pt.pdf',
      );
    });

    testWidgets('is a link for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpLs(_page(_hero(AppLocale.en, cvAvailable: true)));

      expect(
        tester.getSemantics(find.text('Download CV (PDF)')),
        isSemantics(label: 'Download CV (PDF)', isLink: true),
      );
      handle.dispose();
    });
  });

  testWidgets('Email me scrolls to the Contact section', (tester) async {
    await tester.pumpLs(_page(_hero(AppLocale.en)), reducedMotion: true);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0);

    await tester.tap(find.text('Email me'));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(500));
  });

  for (final locale in AppLocale.values) {
    for (final size in const [
      Size(360, 740),
      Size(390, 844),
      Size(1440, 900),
    ]) {
      testWidgets('lays out without overflow at ${size.width.toInt()} px '
          'in ${locale.name}', (tester) async {
        await tester.pumpLs(
          _page(_hero(locale, cvAvailable: true)),
          width: size.width,
          height: size.height,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
