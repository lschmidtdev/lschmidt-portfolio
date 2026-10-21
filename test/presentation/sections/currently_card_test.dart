import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/currently_item.dart';
import 'package:lschmidt_portfolio/presentation/sections/currently_card.dart';

import '../../helpers/fake_portfolio_repository.dart';
import '../../helpers/pump_ls.dart';

void main() {
  final items = FakePortfolioRepository.contentFor(AppLocale.en).currently;

  testWidgets('shows the title, the Available badge and every fresh line', (
    tester,
  ) async {
    await tester.pumpLs(
      Center(
        child: CurrentlyCard(items: items, now: DateTime(2026, 10, 20)),
      ),
    );

    expect(find.text('CURRENTLY'), findsOneWidget);
    expect(find.text('AVAILABLE'), findsOneWidget);
    for (final item in items) {
      expect(find.text(item.label), findsOneWidget);
      expect(find.text(item.value), findsOneWidget);
    }
  });

  testWidgets('with the clock ten years ahead it keeps Status and Based', (
    tester,
  ) async {
    await tester.pumpLs(
      Center(
        child: CurrentlyCard(items: items, now: DateTime(2036, 10, 20)),
      ),
    );

    final undated = items.where((item) => item.date == null);
    final dated = items.where((item) => item.date != null);
    expect(undated, isNotEmpty);
    expect(dated, isNotEmpty);
    for (final item in undated) {
      expect(find.text(item.value), findsOneWidget);
    }
    for (final item in dated) {
      expect(find.text(item.value), findsNothing);
    }
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('BASED'), findsOneWidget);
    expect(find.text('CURRENTLY'), findsOneWidget);
  });

  testWidgets('does not break with no items', (tester) async {
    await tester.pumpLs(
      Center(
        child: CurrentlyCard(
          items: const <CurrentlyItem>[],
          now: DateTime(2026),
        ),
      ),
    );

    expect(find.text('CURRENTLY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('is a labelled region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(
      Center(
        child: CurrentlyCard(items: items, now: DateTime(2026, 10, 20)),
      ),
    );

    expect(
      tester.getSemantics(find.byType(CurrentlyCard)),
      isSemantics(label: 'Currently\nAVAILABLE'),
    );
    handle.dispose();
  });
}
