import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';

import '../../helpers/pump_ls.dart';

void main() {
  testWidgets('centres content at 1200 px', (tester) async {
    await tester.pumpLs(
      const SectionShell(child: SizedBox(key: Key('c'), height: 10)),
      width: 1600,
    );

    final rect = tester.getRect(find.byKey(const Key('c')));
    expect(rect.width, 1200);
    expect(rect.left, 200);
  });

  testWidgets('scrollTo brings the section into view', (tester) async {
    await tester.pumpLs(
      const SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 2000),
            SectionShell(id: SectionId.contact, child: SizedBox(height: 50)),
          ],
        ),
      ),
      reducedMotion: true,
    );

    await SectionId.contact.scrollTo(
      tester.element(find.byType(SingleChildScrollView)),
    );
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
  });

  testWidgets('scrollTo does nothing when the section is not on the page', (
    tester,
  ) async {
    await tester.pumpLs(const SizedBox());

    await SectionId.skills.scrollTo(tester.element(find.byType(Scaffold)));

    expect(tester.takeException(), isNull);
  });

  testWidgets('two scopes can hold the same section at once', (tester) async {
    final first = SectionKeys();
    final second = SectionKeys();
    await tester.pumpLs(
      Column(
        children: [
          SectionScope(
            keys: first,
            child: const SectionShell(
              id: SectionId.work,
              child: SizedBox(height: 10),
            ),
          ),
          SectionScope(
            keys: second,
            child: const SectionShell(
              id: SectionId.work,
              child: SizedBox(height: 10),
            ),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(first[SectionId.work].currentContext, isNotNull);
    expect(second[SectionId.work].currentContext, isNotNull);
    expect(first[SectionId.work], isNot(second[SectionId.work]));
  });

  testWidgets('scrollTo uses the keys of the enclosing scope', (tester) async {
    await tester.pumpLs(
      SectionScope(
        keys: SectionKeys(),
        child: const SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 2000),
              SectionShell(id: SectionId.work, child: SizedBox(height: 50)),
            ],
          ),
        ),
      ),
      reducedMotion: true,
    );

    await SectionId.work.scrollTo(
      tester.element(find.byType(SingleChildScrollView)),
    );
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
