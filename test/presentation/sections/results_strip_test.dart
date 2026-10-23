import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/results_strip.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

ResultsStrip _strip(AppLocale locale) =>
    ResultsStrip(metrics: FakePortfolioRepository.contentFor(locale).metrics);

Finder _value(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == text,
);

void main() {
  testWidgets('shows the four metrics with values in the accent', (
    tester,
  ) async {
    final metrics = FakePortfolioRepository.contentFor(AppLocale.en).metrics;
    await tester.pumpLs(_strip(AppLocale.en));

    expect(metrics, hasLength(4));
    for (final metric in metrics) {
      final plain = metric.unit == null
          ? metric.value
          : '${metric.value} ${metric.unit}';
      final value = tester.widget<RichText>(_value(plain));
      final span = value.text.getSpanForPosition(const TextPosition(offset: 0));
      expect(span?.style?.color, LsColors.dark.accent);
      expect(find.text(metric.label), findsOneWidget);
    }
  });

  testWidgets('renders the unit next to the value in the muted colour', (
    tester,
  ) async {
    await tester.pumpLs(_strip(AppLocale.en));

    expect(_value('5 → 1 min'), findsOne);
    expect(_value('~20 screens'), findsOne);
    final span = tester
        .widget<RichText>(_value('5 → 1 min'))
        .text
        .getSpanForPosition(const TextPosition(offset: 6))!;
    expect(span.style?.color, LsColors.dark.fg3);
  });

  testWidgets('is a labelled region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_strip(AppLocale.en));

    expect(find.bySemanticsLabel('Selected results'), findsOne);
    handle.dispose();
  });

  testWidgets('keeps the cells on one row at 1440 and stacks at 360', (
    tester,
  ) async {
    await tester.pumpLs(SingleChildScrollView(child: _strip(AppLocale.en)));
    expect(
      tester.getTopLeft(_value('100K+')).dy,
      tester.getTopLeft(_value('6 yrs')).dy,
    );

    await tester.pumpLs(
      SingleChildScrollView(child: _strip(AppLocale.en)),
      width: 360,
      height: 740,
    );
    expect(
      tester.getTopLeft(_value('6 yrs')).dy,
      greaterThan(tester.getTopLeft(_value('100K+')).dy),
    );
  });

  for (final locale in AppLocale.values) {
    for (final width in [360.0, 390.0, 768.0, 1440.0]) {
      testWidgets('lays out at ${width.toInt()} px in ${locale.name}', (
        tester,
      ) async {
        await tester.pumpLs(
          SingleChildScrollView(child: _strip(locale)),
          width: width,
          height: 740,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }
}
