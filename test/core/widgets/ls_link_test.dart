import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_link.dart';
import 'package:url_launcher/link.dart';

import '../../helpers/mock_url_launcher.dart';
import '../../helpers/pump_ls.dart';

void main() {
  final target = Uri.parse('https://example.com/page');

  testWidgets('onActivated runs once per tap, before the link opens', (
    tester,
  ) async {
    final order = <String>[];
    final launched = mockUrlLauncher(tester);
    await tester.pumpLs(
      Center(
        child: LsLink(
          label: 'Go',
          href: target,
          target: LinkTarget.blank,
          onActivated: () => order.add('track:${launched.length}'),
        ),
      ),
    );

    await tester.tap(find.text('GO'));
    await tester.pump();

    expect(order, ['track:0']);
    expect(launched, [target.toString()]);
  });

  testWidgets('a throwing callback still lets the link open', (tester) async {
    final launched = mockUrlLauncher(tester);
    await tester.pumpLs(
      Center(
        child: LsLink(
          label: 'Go',
          href: target,
          target: LinkTarget.blank,
          onActivated: () => throw StateError('blocked'),
        ),
      ),
    );

    await tester.tap(find.text('GO'));
    await tester.pump();

    expect(launched, [target.toString()]);
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('a link is focusable and keeps its label and link role', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(
      Center(
        child: LsLink(label: 'Go', onPressed: () {}),
      ),
    );

    expect(
      tester.getSemantics(find.text('GO')),
      isSemantics(
        label: 'Go',
        isLink: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('an href link is focusable and keeps its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(
      Center(
        child: LsLink(label: 'Go', href: target),
      ),
    );

    expect(
      tester.getSemantics(find.text('GO')),
      isSemantics(
        label: 'Go',
        isLink: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
