import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/experience_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_footer.dart';
import 'package:lschmidt_portfolio/presentation/sections/skills_section.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

Widget _body(AppLocale locale) {
  final content = FakePortfolioRepository.contentFor(locale);
  return SectionScope(
    keys: SectionKeys(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExperienceSection(roles: content.roles),
        SkillsSection(
          groups: content.skillGroups,
          education: content.education,
          languages: content.languages,
        ),
        const SiteFooter(cvAvailable: true),
      ],
    ),
  );
}

void main() {
  goldenTest(
    'experience, skills and footer at 1440',
    fileName: 'lower_desktop',
    builder: () => GoldenTestGroup(
      columns: 1,
      columnWidthBuilder: (_) => const FixedColumnWidth(1440 + 32),
      children: [
        for (final light in [false, true])
          GoldenTestScenario(
            name: '1440 ${light ? 'light' : 'dark'}',
            child: atWidth(1440, _body(AppLocale.en), light: light),
          ),
      ],
    ),
  );

  goldenTest(
    'experience, skills and footer at 390',
    fileName: 'lower_phone',
    builder: () => GoldenTestGroup(
      columns: 2,
      columnWidthBuilder: (_) => const FixedColumnWidth(390 + 32),
      children: [
        for (final light in [false, true])
          GoldenTestScenario(
            name: '390 ${light ? 'light' : 'dark'}',
            child: atWidth(390, _body(AppLocale.en), light: light),
          ),
      ],
    ),
  );
}
