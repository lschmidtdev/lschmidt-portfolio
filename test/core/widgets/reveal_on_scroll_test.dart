import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_motion.dart';
import 'package:lschmidt_portfolio/core/widgets/reveal_on_scroll.dart';

import '../../helpers/pump_ls.dart';

Widget _page() => const SingleChildScrollView(
  child: Column(
    children: [
      SizedBox(height: 2000),
      RevealOnScroll(child: SizedBox(key: Key('r'), height: 100)),
      SizedBox(height: 2000),
    ],
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(RevealOnScroll),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

void _scrollTo(WidgetTester tester, double offset) => tester
    .state<ScrollableState>(find.byType(Scrollable))
    .position
    .jumpTo(offset);

void main() {
  testWidgets('a child on screen stays visible', (tester) async {
    await tester.pumpLs(
      const RevealOnScroll(child: SizedBox(key: Key('r'), height: 100)),
    );
    await tester.pump();

    expect(_opacity(tester), 1);
  });

  testWidgets('a child below the screen is hidden, then fades in once', (
    tester,
  ) async {
    await tester.pumpLs(_page());
    await tester.pump();
    expect(_opacity(tester), 0);

    _scrollTo(tester, 1800);
    await tester.pump();
    await tester.pump(LsMotion.reveal ~/ 2);
    expect(_opacity(tester), inExclusiveRange(0, 1));

    await tester.pump(LsMotion.reveal);
    expect(_opacity(tester), 1);

    _scrollTo(tester, 0);
    await tester.pump();
    expect(_opacity(tester), 1);
  });

  testWidgets('under reduced motion a child below the screen is visible', (
    tester,
  ) async {
    await tester.pumpLs(_page(), reducedMotion: true);
    await tester.pump();

    expect(_opacity(tester), 1);
  });

  testWidgets('a hidden child ignores pointer input', (tester) async {
    await tester.pumpLs(_page());
    await tester.pump();

    final ignore = tester.widget<IgnorePointer>(
      find
          .descendant(
            of: find.byType(RevealOnScroll),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignore.ignoring, isTrue);
  });
}
