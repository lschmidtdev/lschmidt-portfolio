import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/hero.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_header.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

Widget _top() {
  final content = FakePortfolioRepository.contentFor(AppLocale.en);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SiteHeader(
        locale: AppLocale.en,
        onLocaleSelected: (_) {},
        onToggleTheme: () {},
      ),
      HeroSection(
        profile: content.profile,
        currently: content.currently,
        locale: AppLocale.en,
        now: DateTime(2026, 10, 20),
        cvAvailable: true,
      ),
    ],
  );
}

void main() {
  goldenTest(
    'header and hero at 1440',
    fileName: 'home_top_desktop',
    builder: () => GoldenTestGroup(
      columns: 1,
      columnWidthBuilder: (_) => const FixedColumnWidth(1440 + 32),
      children: [
        for (final light in [false, true])
          GoldenTestScenario(
            name: '1440 ${light ? 'light' : 'dark'}',
            child: atWidth(1440, _top(), light: light),
          ),
      ],
    ),
  );

  goldenTest(
    'header and hero at 390',
    fileName: 'home_top_phone',
    builder: () => GoldenTestGroup(
      columns: 2,
      columnWidthBuilder: (_) => const FixedColumnWidth(390 + 32),
      children: [
        for (final light in [false, true])
          GoldenTestScenario(
            name: '390 ${light ? 'light' : 'dark'}',
            child: atWidth(390, _top(), light: light),
          ),
      ],
    ),
  );
}
