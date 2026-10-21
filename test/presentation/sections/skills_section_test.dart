import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/skills_section.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

Widget _skills(AppLocale locale) {
  final content = FakePortfolioRepository.contentFor(locale);
  return SingleChildScrollView(
    child: SkillsSection(
      groups: content.skillGroups,
      education: content.education,
      languages: content.languages,
    ),
  );
}

Color? _color(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('shows the four groups with their items joined by dots', (
    tester,
  ) async {
    final groups = FakePortfolioRepository.contentFor(AppLocale.en).skillGroups;
    await tester.pumpLs(_skills(AppLocale.en));

    expect(find.text('Skills'), findsOne);
    expect(groups, hasLength(4));
    for (final group in groups) {
      expect(find.text(group.title), findsOne);
      expect(find.text(group.items.join(' · ')), findsOne);
    }
  });

  testWidgets('only the primary group is accented', (tester) async {
    await tester.pumpLs(_skills(AppLocale.en));

    expect(_color(tester, 'CORE · DAILY USE'), LsColors.dark.accent);
    for (final title in ['WORKING KNOWLEDGE', 'APPLIED AI', 'DELIVERY']) {
      expect(_color(tester, title), LsColors.dark.fg3);
    }
  });

  testWidgets('shows education and languages', (tester) async {
    await tester.pumpLs(_skills(AppLocale.en));

    expect(
      find.textContaining(
        'B.Sc. Software Engineering, Ampli — expected Dec 2027 · '
        'IT Technical Degree, IFSC — 2017',
        findRichText: true,
      ),
      findsOne,
    );
    expect(
      find.textContaining(
        'Portuguese (native) · English (C1)',
        findRichText: true,
      ),
      findsOne,
    );
    expect(find.textContaining('EDUCATION', findRichText: true), findsOne);
    expect(find.textContaining('LANGUAGES', findRichText: true), findsOne);
  });

  testWidgets('gives the header Skills link its scroll target', (tester) async {
    await tester.pumpLs(_skills(AppLocale.en));

    expect(SectionId.skills.key.currentContext, isNotNull);
  });

  testWidgets('the heading is a semantic header', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_skills(AppLocale.en));

    expect(
      tester.getSemantics(find.text('Skills')),
      isSemantics(label: 'Skills', isHeader: true),
    );
    handle.dispose();
  });

  for (final locale in AppLocale.values) {
    for (final width in [360.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
      testWidgets('lays out without overflow at ${width.toInt()} px in '
          '${locale.name}', (tester) async {
        await tester.pumpLs(
          _skills(locale),
          width: width,
          height: 740,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
