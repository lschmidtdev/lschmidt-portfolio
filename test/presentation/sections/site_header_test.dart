import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_header.dart';

import '../../helpers/mock_url_launcher.dart';
import '../../helpers/pump_ls.dart';
import '../../helpers/pushed_routes.dart';

Widget _page({
  AppLocale locale = AppLocale.en,
  ValueChanged<AppLocale>? onLocale,
  VoidCallback? onTheme,
}) => SingleChildScrollView(
  child: Column(
    children: [
      SiteHeader(
        locale: locale,
        onLocaleSelected: onLocale ?? (_) {},
        onToggleTheme: onTheme ?? () {},
      ),
      const SizedBox(height: 1500),
      const SectionShell(id: SectionId.work, child: SizedBox(height: 100)),
      const SizedBox(height: 1500),
      const SectionShell(id: SectionId.contact, child: SizedBox(height: 100)),
    ],
  ),
);

void main() {
  testWidgets('shows the brand and the four nav links in English', (
    tester,
  ) async {
    await tester.pumpLs(_page());

    expect(find.text('Lucas Schmidt'), findsOneWidget);
    expect(find.text('LS'), findsOneWidget);
    for (final label in ['WORK', 'EXPERIENCE', 'SKILLS', 'CONTACT']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows the nav links in Portuguese', (tester) async {
    await tester.pumpLs(_page(locale: AppLocale.pt), locale: AppLocale.pt);

    for (final label in ['TRABALHO', 'EXPERIÊNCIA', 'HABILIDADES', 'CONTATO']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('nav links are links and scroll to their section', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_page(), reducedMotion: true);
    expect(
      tester.getSemantics(find.text('WORK')),
      isSemantics(label: 'Work', isLink: true, hasTapAction: true),
    );

    await tester.tap(find.text('CONTACT'));
    await settlePushedRoutes(tester);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(1500));
    handle.dispose();
  });

  for (final (locale, labels, root) in [
    (AppLocale.en, ['WORK', 'EXPERIENCE', 'SKILLS', 'CONTACT'], '/'),
    (
      AppLocale.pt,
      ['TRABALHO', 'EXPERIÊNCIA', 'HABILIDADES', 'CONTATO'],
      '/pt',
    ),
  ]) {
    testWidgets('the brand and nav links carry real urls in ${locale.name}', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpLs(_page(locale: locale), locale: locale);

      Uri? linkUrl(String text) =>
          tester.getSemantics(find.text(text)).getSemanticsData().linkUrl;
      expect(linkUrl('Lucas Schmidt'), Uri.parse(root));
      final fragments = ['work', 'experience', 'skills', 'contact'];
      for (var i = 0; i < labels.length; i++) {
        expect(
          linkUrl(labels[i]),
          Uri.parse('$root#${fragments[i]}'),
          reason: labels[i],
        );
      }
      expect(
        tester.getSemantics(find.text('Lucas Schmidt')),
        isSemantics(isLink: true, hasTapAction: true),
      );
      handle.dispose();
    });
  }

  testWidgets('a plain activation scrolls and leaves the url alone', (
    tester,
  ) async {
    final pushed = recordPushedRoutes(tester);
    await tester.pumpLs(_page(), reducedMotion: true);
    final updates = recordRouteUpdates(tester);

    await tester.tap(find.text('Lucas Schmidt'));
    await settlePushedRoutes(tester);
    await tester.tap(find.text('CONTACT'));
    await settlePushedRoutes(tester);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(1500));
    expect(pushed, isEmpty);
    expect(updates, isEmpty);
  });

  testWidgets('Enter on a nav link scrolls and leaves the url alone', (
    tester,
  ) async {
    final pushed = recordPushedRoutes(tester);
    await tester.pumpLs(_page(), reducedMotion: true);
    final updates = recordRouteUpdates(tester);

    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settlePushedRoutes(tester);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(1500));
    expect(pushed, isEmpty);
    expect(updates, isEmpty);
  });

  for (final modifier in [
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.shiftLeft,
  ]) {
    testWidgets('${modifier.keyLabel} + click opens the url in a new tab', (
      tester,
    ) async {
      final pushed = recordPushedRoutes(tester);
      final launched = mockUrlLauncher(tester);
      await tester.pumpLs(_page(), reducedMotion: true);

      await tester.sendKeyDownEvent(modifier);
      await tester.tap(find.text('CONTACT'));
      await tester.sendKeyUpEvent(modifier);
      await settlePushedRoutes(tester);

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, 0);
      expect(pushed, isEmpty);
      expect(launched, hasLength(1));
      expect(launched.single, endsWith('/#contact'));
    });
  }

  testWidgets('the selected language is marked and the other one switches', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final picked = <AppLocale>[];
    await tester.pumpLs(_page(onLocale: picked.add));

    expect(
      tester.getSemantics(find.text('EN')),
      isSemantics(label: 'English', isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('PT')),
      isSemantics(label: 'Português', isButton: true, isSelected: false),
    );

    await tester.tap(find.text('PT'));

    expect(picked, [AppLocale.pt]);
    handle.dispose();
  });

  testWidgets('the icon-only theme button has an accessible name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var toggles = 0;
    await tester.pumpLs(_page(onTheme: () => toggles++));

    final button = find.bySemanticsLabel('Switch to light theme');
    expect(button, findsOneWidget);
    await tester.tap(button);

    expect(toggles, 1);
    handle.dispose();
  });

  testWidgets('the theme button is labelled in Portuguese', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_page(locale: AppLocale.pt), locale: AppLocale.pt);

    expect(find.bySemanticsLabel('Mudar para o tema claro'), findsOne);
    handle.dispose();
  });

  testWidgets('every control keeps a 48 px target', (tester) async {
    await tester.pumpLs(_page());

    for (final text in [
      'WORK',
      'EXPERIENCE',
      'SKILLS',
      'CONTACT',
      'EN',
      'PT',
    ]) {
      final target = find.ancestor(
        of: find.text(text),
        matching: find.byType(GestureDetector),
      );
      final size = tester.getSize(target.first);
      expect(size.height, greaterThanOrEqualTo(48), reason: text);
      expect(size.width, greaterThanOrEqualTo(48), reason: text);
    }
    final theme = find.bySemanticsLabel('Switch to light theme');
    expect(tester.getSize(theme).height, greaterThanOrEqualTo(48));
  });

  for (final locale in AppLocale.values) {
    testWidgets('lays out at 360 px in ${locale.name} without overflow', (
      tester,
    ) async {
      await tester.pumpLs(
        _page(locale: locale),
        width: 360,
        height: 740,
        locale: locale,
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the language options and the theme button are focusable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_page());

    expect(
      tester.getSemantics(find.text('PT')),
      isSemantics(
        label: 'Português',
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byIcon(Icons.contrast)),
      isSemantics(
        label: 'Switch to light theme',
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('every header control is reachable with Tab', (tester) async {
    await tester.pumpLs(_page());
    final reached = <String>[];
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      final texts = find.descendant(
        of: find.byElementPredicate((e) => e == focused),
        matching: find.byType(Text),
      );
      reached.add(
        texts.evaluate().isEmpty
            ? 'icon'
            : (texts.evaluate().last.widget as Text).data!,
      );
    }

    expect(reached, [
      'Lucas Schmidt',
      'WORK',
      'EXPERIENCE',
      'SKILLS',
      'CONTACT',
      'EN',
      'PT',
      'icon',
    ]);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('lays out at 360 px with text scale $scale without overflow', (
      tester,
    ) async {
      await tester.pumpLs(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: _page(),
          ),
        ),
        width: 360,
        height: 740,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SiteHeader), findsOneWidget);
    });
  }

  testWidgets('the theme button names the theme it switches to', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpLs(_page());
    expect(
      tester.getSemantics(find.byIcon(Icons.contrast)),
      isSemantics(label: 'Switch to light theme', isButton: true),
    );

    await tester.pumpLs(_page(), light: true);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byIcon(Icons.contrast)),
      isSemantics(label: 'Switch to dark theme', isButton: true),
    );

    await tester.pumpLs(_page(), light: true, locale: AppLocale.pt);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Mudar para o tema escuro'), findsOne);
    handle.dispose();
  });
}
