import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lschmidt_portfolio/app.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/data/repositories/web3forms_contact_repository.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/portfolio_content.dart';
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/analytics_repository.dart';
import 'package:lschmidt_portfolio/domain/repositories/contact_repository.dart';
import 'package:lschmidt_portfolio/domain/repositories/portfolio_repository.dart';
import 'package:lschmidt_portfolio/presentation/cubits/locale_cubit.dart';
import 'package:lschmidt_portfolio/presentation/cubits/theme_cubit.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/presentation/sections/contact_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/experience_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/project_tile.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_footer.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_header.dart';
import 'package:lschmidt_portfolio/presentation/sections/skills_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/work_section.dart';
import 'package:lschmidt_portfolio/presentation/sections/results_strip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'helpers/fake_portfolio_repository.dart';
import 'helpers/pushed_routes.dart';
import 'helpers/recording_analytics.dart';

ScrollableState _pageScrollable(WidgetTester tester) =>
    tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(SingleChildScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

class _AcceptingContactRepository implements ContactRepository {
  @override
  Future<void> send(ContactMessage message) async {}
}

class _PendingRepository implements PortfolioRepository {
  @override
  Future<PortfolioContent> load(AppLocale locale) =>
      Completer<PortfolioContent>().future;
}

void main() {
  testWidgets('shows the header and the hero from the loaded content', (
    tester,
  ) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Lucas\nSchmidt'), findsOneWidget);
    expect(find.text('Lucas Schmidt'), findsOneWidget);
    expect(find.text('CURRENTLY'), findsOneWidget);
  });

  testWidgets('shows the name and a mail link when the content fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      App(repository: FakePortfolioRepository(failing: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lucas\nSchmidt'), findsOneWidget);
    final mail = tester.widget<LsButton>(find.byType(LsButton));
    expect(mail.href, SiteConfig.mailto);
  });

  testWidgets('hides the footer while the content is loading', (tester) async {
    await tester.pumpWidget(App(repository: _PendingRepository()));
    await tester.pump();

    expect(find.byType(SiteFooter), findsNothing);
  });

  testWidgets('the default contact wiring sends the configured access key', (
    tester,
  ) async {
    final bodies = <String>[];
    await tester.pumpWidget(
      App(
        repository: FakePortfolioRepository(),
        httpClient: MockClient((request) async {
          bodies.add(request.body);
          return http.Response('{"success":true}', 200);
        }),
      ),
    );
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.ensureVisible(field('Name'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Ana Recruiter');
    await tester.enterText(field('Email'), 'ana@example.com');
    await tester.enterText(
      field('Message'),
      'We have a remote Flutter role for you.',
    );
    await tester.ensureVisible(find.text('Send message'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();

    if (SiteConfig.web3formsKey.isEmpty) {
      expect(bodies, isEmpty);
    } else {
      expect(bodies, hasLength(1));
      expect(jsonDecode(bodies.single)['access_key'], SiteConfig.web3formsKey);
    }
  });

  testWidgets('the app provides the injected analytics to the contact form', (
    tester,
  ) async {
    final analytics = RecordingAnalytics();
    await tester.pumpWidget(
      App(
        repository: FakePortfolioRepository(),
        contactRepository: _AcceptingContactRepository(),
        analyticsRepository: analytics,
      ),
    );
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.ensureVisible(field('Name'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Ana Recruiter');
    await tester.enterText(field('Email'), 'ana@example.com');
    await tester.enterText(
      field('Message'),
      'We have a remote Flutter role for you.',
    );
    await tester.ensureVisible(find.text('Send message'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();

    expect(analytics.events, [AnalyticsEvent.contactFormSent]);
  });

  testWidgets('keeps the footer when the content fails', (tester) async {
    await tester.pumpWidget(
      App(repository: FakePortfolioRepository(failing: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SiteFooter), findsOneWidget);
  });

  testWidgets('the theme button toggles the theme', (tester) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    final cubit = tester.element(find.byType(Scaffold)).read<ThemeCubit>();
    expect(cubit.state, ThemeMode.dark);

    await tester.tap(find.byIcon(Icons.contrast));
    await tester.pumpAndSettle();

    expect(cubit.state, ThemeMode.light);
  });

  testWidgets('shows the results strip and the selected work', (tester) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Selected work'), findsOneWidget);
    expect(find.byType(ResultsStrip), findsOneWidget);
    expect(find.byType(ProjectTile), findsNWidgets(5));
  });

  testWidgets('the Work link scrolls to the selected work', (tester) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    final scrollable = _pageScrollable(tester);
    expect(scrollable.position.pixels, 0);

    await tester.tap(find.text('WORK'));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
  });

  for (final (label, id) in [
    ('EXPERIENCE', SectionId.experience),
    ('SKILLS', SectionId.skills),
  ]) {
    testWidgets('the $label link scrolls to its section', (tester) async {
      await tester.pumpWidget(App(repository: FakePortfolioRepository()));
      await tester.pumpAndSettle();
      final scrollable = _pageScrollable(tester);
      final key = id.keyIn(tester.element(find.byType(Scaffold)));
      expect(key.currentContext, isNotNull);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(0));
      expect(tester.getTopLeft(find.byKey(key)).dy, closeTo(0, 1));
    });
  }

  testWidgets('shows experience, skills and the footer in design order', (
    tester,
  ) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();

    final tops = [
      for (final type in [
        WorkSection,
        ExperienceSection,
        SkillsSection,
        ContactSection,
        SiteFooter,
      ])
        tester.getTopLeft(find.byType(type, skipOffstage: false)).dy,
    ];
    expect(tops, [...tops]..sort());
  });

  testWidgets('switching the language keeps a single work section', (
    tester,
  ) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PT'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Trabalhos selecionados'), findsOneWidget);
    expect(find.byType(ProjectTile), findsNWidgets(5));
  });

  testWidgets('the Contact link scrolls to the contact section', (
    tester,
  ) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    final scrollable = _pageScrollable(tester);
    final key = SectionId.contact.keyIn(tester.element(find.byType(Scaffold)));
    expect(key.currentContext, isNotNull);

    await tester.tap(find.text('CONTACT').first);
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
    final top = tester.getTopLeft(find.byKey(key)).dy;
    expect(top, inInclusiveRange(-30, 1));
    final name = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Name',
      ),
    );
    expect(name.top, greaterThanOrEqualTo(0));
    expect(name.bottom, lessThanOrEqualTo(600));
  });

  for (final (path, contact) in [('/', 'CONTACT'), ('/pt', 'CONTATO')]) {
    testWidgets('on $path a click on Contact scrolls and keeps the url', (
      tester,
    ) async {
      await tester.pumpWidget(
        App(initialLocation: path, repository: FakePortfolioRepository()),
      );
      await tester.pumpAndSettle();
      final updates = recordRouteUpdates(tester);
      final page = tester.element(find.byType(Scaffold));
      final locale = page.read<LocaleCubit>().state;

      await tester.tap(find.text(contact).first);
      await settlePushedRoutes(tester);

      final scrolled = _pageScrollable(tester).position.pixels;
      expect(scrolled, greaterThan(0));
      expect(updates, isEmpty);
      expect(
        GoRouter.of(page).routeInformationProvider.value.uri.toString(),
        path,
      );
      expect(page.read<LocaleCubit>().state, locale);
      expect(
        FocusManager.instance.primaryFocus,
        SectionId.contact.focusIn(tester.element(find.byType(SiteHeader))),
      );
      await tester.pumpAndSettle();
      expect(_pageScrollable(tester).position.pixels, scrolled);
    });
  }

  testWidgets('the brand scrolls back to the top and keeps the url', (
    tester,
  ) async {
    await tester.pumpWidget(
      App(initialLocation: '/pt', repository: FakePortfolioRepository()),
    );
    await tester.pumpAndSettle();
    final updates = recordRouteUpdates(tester);
    final page = tester.element(find.byType(Scaffold));
    _pageScrollable(tester).position.jumpTo(30);
    await tester.pump();

    await tester.tap(find.text('Lucas Schmidt').first);
    await settlePushedRoutes(tester);

    expect(_pageScrollable(tester).position.pixels, 0);
    expect(updates, isEmpty);
    expect(
      GoRouter.of(page).routeInformationProvider.value.uri.toString(),
      '/pt',
    );
    expect(page.read<LocaleCubit>().state, AppLocale.pt);
  });

  testWidgets('Email me in the hero scrolls to the contact section', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    final scrollable = _pageScrollable(tester);
    final key = SectionId.contact.keyIn(tester.element(find.byType(Scaffold)));

    await tester.tap(find.text('Email me'));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.getTopLeft(find.byKey(key)).dy, lessThan(900));
  });

  testWidgets('without an access key the form fails with the mailto fallback', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      App(
        repository: FakePortfolioRepository(),
        contactRepository: Web3FormsContactRepository(
          MockClient((_) async {
            requests++;
            return http.Response('{"success":true}', 200);
          }),
          accessKey: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.ensureVisible(field('Name'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Ana Recruiter');
    await tester.enterText(field('Email'), 'ana@example.com');
    await tester.enterText(
      field('Message'),
      'We have a remote Flutter role for you.',
    );

    await tester.ensureVisible(find.text('Send message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();

    expect(requests, 0);
    expect(find.textContaining('could not be sent'), findsOneWidget);
    expect(find.text('EMAIL ME DIRECTLY'), findsOneWidget);
  });

  group('navigation moves the focus', () {
    Element focusedElement() =>
        FocusManager.instance.primaryFocus!.context! as Element;

    void expectFocusInside(WidgetTester tester, Type section) {
      final focused = focusedElement();
      var inside = false;
      focused.visitAncestorElements((ancestor) {
        inside = ancestor.widget.runtimeType == section;
        return !inside;
      });
      expect(inside, isTrue, reason: '$focused should be inside $section');
      final box = focused.renderObject! as RenderBox;
      final top = box.localToGlobal(Offset.zero).dy;
      final height =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(top, greaterThanOrEqualTo(0));
      expect(top + box.size.height, lessThanOrEqualTo(height));
    }

    Future<void> pressTab(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    bool focusedInside(bool Function(Widget widget) test) {
      var inside = false;
      focusedElement().visitAncestorElements((ancestor) {
        inside = test(ancestor.widget);
        return !inside;
      });
      return inside;
    }

    testWidgets('a tap on Contact focuses the heading, not a text field', (
      tester,
    ) async {
      await tester.pumpWidget(App(repository: FakePortfolioRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTACT').first);
      await tester.pumpAndSettle();

      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      expect(focusedInside((w) => w is EditableText), isFalse);
      expect(
        find.descendant(
          of: find.byElementPredicate((e) => e == focusedElement()),
          matching: find.textContaining('Hiring a', findRichText: true),
        ),
        findsOneWidget,
      );
      expectFocusInside(tester, ContactSection);
    });

    testWidgets('Enter on Contact from the keyboard focuses the Name field', (
      tester,
    ) async {
      await tester.pumpWidget(App(repository: FakePortfolioRepository()));
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(
        find.descendant(
          of: find.byElementPredicate((e) => e == focusedElement()),
          matching: find.text('CONTACT'),
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      expect(
        focusedInside(
          (w) => w is TextField && w.decoration?.labelText == 'Name',
        ),
        isTrue,
      );
      expectFocusInside(tester, ContactSection);
    });

    testWidgets('the Contact link, then Tab, lands inside the form', (
      tester,
    ) async {
      await tester.pumpWidget(App(repository: FakePortfolioRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTACT').first);
      await tester.pumpAndSettle();
      await pressTab(tester);

      expectFocusInside(tester, ContactSection);
    });

    testWidgets('Email me in the hero, then Tab, lands inside the form', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(App(repository: FakePortfolioRepository()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Email me'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Email me'));
      await tester.pumpAndSettle();
      await pressTab(tester);

      expectFocusInside(tester, ContactSection);
    });

    testWidgets('the Work link focuses the heading, Tab moves on from it', (
      tester,
    ) async {
      await tester.pumpWidget(App(repository: FakePortfolioRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('WORK'));
      await tester.pumpAndSettle();

      expectFocusInside(tester, WorkSection);
      expect(
        find.descendant(
          of: find.byElementPredicate((e) => e == focusedElement()),
          matching: find.text('Selected work'),
        ),
        findsOneWidget,
      );
      await pressTab(tester);
      final next = focusedElement();
      var inHeader = false;
      next.visitAncestorElements((ancestor) {
        inHeader =
            ancestor.widget is SiteHeader || ancestor.widget is WorkSection;
        return !inHeader;
      });
      expect(inHeader, isFalse, reason: '$next should come after the heading');
    });

    testWidgets('with reduced motion the focus moves on the same frame', (
      tester,
    ) async {
      final reduced = ValueNotifier(true);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        App(repository: FakePortfolioRepository(), reducedMotion: reduced),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SKILLS'));
      await tester.pump();

      expectFocusInside(tester, SkillsSection);
    });
  });

  testWidgets('switching the language keeps the scroll position', (
    tester,
  ) async {
    await tester.pumpWidget(App(repository: FakePortfolioRepository()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(SkillsSection));
    await tester.pumpAndSettle();
    final before = _pageScrollable(tester).position.pixels;
    expect(before, greaterThan(0));
    expect(find.text('Skills'), findsOneWidget);

    tester
        .element(find.byType(Scaffold))
        .read<LocaleCubit>()
        .select(AppLocale.pt);
    await tester.pumpAndSettle();

    expect(_pageScrollable(tester).position.pixels, before);
    expect(find.text('Habilidades'), findsOneWidget);
    expect(find.text('Skills'), findsNothing);
  });

  for (final path in ['/', '/pt']) {
    testWidgets('the whole page at 360 x 740 on $path has no layout errors', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        App(initialLocation: path, repository: FakePortfolioRepository()),
      );
      await tester.pumpAndSettle();
      final position = _pageScrollable(tester).position;
      expect(position.maxScrollExtent, greaterThan(0));

      while (position.pixels < position.maxScrollExtent) {
        position.jumpTo(
          (position.pixels + 500).clamp(0, position.maxScrollExtent),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${position.pixels}');
      }
      expect(find.byType(SiteFooter), findsOneWidget);
    });
  }
}
