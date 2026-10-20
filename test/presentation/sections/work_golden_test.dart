import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/results_strip.dart';
import 'package:lschmidt_portfolio/presentation/sections/work_section.dart';

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
        ResultsStrip(metrics: content.metrics),
        WorkSection(projects: content.projects),
      ],
    ),
  );
}

void main() {
  goldenTest(
    'results and work at 1440',
    fileName: 'work_desktop',
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
    'results and work at 390',
    fileName: 'work_phone',
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
