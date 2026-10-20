import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';

import '../../helpers/pump_ls.dart';

void main() {
  testWidgets('onPressed fires on tap', (tester) async {
    var taps = 0;
    await tester.pumpLs(
      Center(
        child: LsButton.primary(label: 'Go', onPressed: () => taps++),
      ),
    );

    await tester.tap(find.text('Go'));

    expect(taps, 1);
  });

  testWidgets('Enter and Space activate the focused button', (tester) async {
    var taps = 0;
    await tester.pumpLs(
      Center(
        child: LsButton.ghost(label: 'Go', onPressed: () => taps++),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(taps, 2);
  });

  testWidgets('an action button is a button, an href button is a link', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(
      Column(
        children: [
          LsButton.primary(label: 'Act', onPressed: () {}),
          LsButton.primary(label: 'Open', href: Uri.parse('/cv.pdf')),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.text('Act')),
      isSemantics(label: 'Act', isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.text('Open')),
      isSemantics(label: 'Open', isLink: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('keeps the 48 px minimum target', (tester) async {
    await tester.pumpLs(
      Align(
        alignment: Alignment.topLeft,
        child: LsButton.ghost(label: 'Go', onPressed: () {}),
      ),
    );

    expect(
      tester.getSize(find.byType(LsButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the primary button fills with the accent, the ghost has a '
      'hairline', (tester) async {
    await tester.pumpLs(
      Column(
        children: [
          LsButton.primary(label: 'A', onPressed: () {}),
          LsButton.ghost(label: 'B', onPressed: () {}),
        ],
      ),
    );

    final decorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .toList();
    expect(decorations.where((d) => d.color != null), hasLength(1));
    expect(decorations.where((d) => d.border != null), hasLength(1));
  });

  testWidgets('the inverse button fills with fg, sets bg text and pads 20', (
    tester,
  ) async {
    await tester.pumpLs(
      Center(
        child: LsButton.inverse(label: 'Go', onPressed: () {}),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(LsButton),
        matching: find.byType(Container),
      ),
    );
    expect((container.decoration! as BoxDecoration).color, LsColors.dark.fg);
    expect((container.padding! as EdgeInsets).horizontal, 40);
    expect(tester.widget<Text>(find.text('Go')).style?.color, LsColors.dark.bg);
  });
}
