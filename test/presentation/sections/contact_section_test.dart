import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_link.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/contact_repository.dart';
import 'package:lschmidt_portfolio/presentation/cubits/contact_form_cubit.dart';
import 'package:lschmidt_portfolio/presentation/sections/contact_section.dart';

import '../../helpers/pump_ls.dart';

class _Repository implements ContactRepository {
  _Repository({this.fail = false, this.gate});

  final bool fail;
  final Completer<void>? gate;
  final sent = <ContactMessage>[];

  @override
  Future<void> send(ContactMessage message) async {
    sent.add(message);
    await gate?.future;
    if (fail) throw const ContactSendException('failed');
  }
}

Widget _section(
  _Repository repository, {
  AppLocale locale = AppLocale.en,
  bool cvAvailable = false,
}) => BlocProvider(
  create: (_) => ContactFormCubit(repository),
  child: SingleChildScrollView(
    child: ContactSection(locale: locale, cvAvailable: cvAvailable),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  _Repository repository, {
  double width = 1440,
  AppLocale locale = AppLocale.en,
  bool cvAvailable = false,
}) => tester.pumpLs(
  _section(repository, locale: locale, cvAvailable: cvAvailable),
  width: width,
  height: 1200,
  locale: locale,
  reducedMotion: true,
);

Finder _field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

Future<void> _fillValid(WidgetTester tester) async {
  await tester.enterText(_field('Name'), 'Ana Recruiter');
  await tester.enterText(_field('Email'), 'ana@example.com');
  await tester.enterText(_field('Company (optional)'), 'Acme');
  await tester.enterText(
    _field('Message'),
    'We have a remote Flutter role for you.',
  );
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.text('Send message'));
  await tester.pump();
}

Finder _mailtoLink(String subject) => find.byWidgetPredicate(
  (w) =>
      w is LsLink &&
      w.href == Uri.parse('mailto:${SiteConfig.email}?subject=$subject'),
);

void main() {
  testWidgets('shows the heading, the email and the labelled fields', (
    tester,
  ) async {
    await _pump(tester, _Repository());

    expect(find.text('CONTACT'), findsOneWidget);
    expect(find.textContaining('Hiring a'), findsOneWidget);
    expect(find.text(SiteConfig.email), findsOneWidget);
    for (final label in ['Name', 'Email', 'Company (optional)', 'Message']) {
      expect(_field(label), findsOneWidget, reason: label);
    }
    expect(find.text('Send message'), findsOneWidget);
    expect(find.text('LinkedIn ↗'), findsOneWidget);
    expect(find.text('GitHub ↗'), findsOneWidget);
  });

  testWidgets('the CV button follows cvAvailable', (tester) async {
    await _pump(tester, _Repository(), cvAvailable: true);
    expect(find.text('CV · PDF ↓'), findsOneWidget);

    await _pump(tester, _Repository(), cvAvailable: false);
    expect(find.text('CV · PDF ↓'), findsNothing);
  });

  testWidgets('empty fields show the three validation errors and do not send', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);

    await _tapSend(tester);

    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(find.text('Please write at least 10 characters.'), findsOneWidget);
    expect(repository.sent, isEmpty);
  });

  testWidgets('validation errors are announced', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _Repository());

    await _tapSend(tester);
    await tester.pumpAndSettle();

    final error = tester.getSemantics(find.text('Please enter your name.'));
    expect(error.label, 'Please enter your name.');
    expect(
      tester.getSemantics(_field('Name')).getSemanticsData().validationResult,
      SemanticsValidationResult.invalid,
    );
    handle.dispose();
  });

  testWidgets('fields are exposed with their labels', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _Repository());

    for (final label in ['Name', 'Email', 'Company (optional)', 'Message']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    handle.dispose();
  });

  testWidgets('a valid form sends the trimmed message and shows the thanks', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);
    await _fillValid(tester);

    await _tapSend(tester);
    await tester.pumpAndSettle();

    expect(repository.sent, hasLength(1));
    final sent = repository.sent.single;
    expect(sent.name, 'Ana Recruiter');
    expect(sent.email, 'ana@example.com');
    expect(sent.company, 'Acme');
    expect(sent.message, 'We have a remote Flutter role for you.');
    expect(sent.honeypot, isEmpty);
    expect(find.text('Message sent.'), findsOneWidget);
    expect(find.text('Send message'), findsNothing);
  });

  testWidgets('send another shows an empty form again', (tester) async {
    await _pump(tester, _Repository());
    await _fillValid(tester);
    await _tapSend(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('SEND ANOTHER MESSAGE'));
    await tester.pumpAndSettle();

    expect(find.text('Send message'), findsOneWidget);
    expect(tester.widget<TextField>(_field('Name')).controller?.text, isEmpty);
  });

  testWidgets('shows sending and ignores a second tap while it lasts', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _Repository(gate: gate);
    await _pump(tester, repository);
    await _fillValid(tester);

    await _tapSend(tester);
    expect(find.text('Sending…'), findsOneWidget);
    await tester.tap(find.text('Send message'), warnIfMissed: false);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();

    expect(repository.sent, hasLength(1));
  });

  testWidgets('sending is announced once, by the status text only', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final gate = Completer<void>();
    await _pump(tester, _Repository(gate: gate));
    await _fillValid(tester);

    await _tapSend(tester);

    expect(find.bySemanticsLabel('Sending…'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('moves focus to the sent heading', (tester) async {
    await _pump(tester, _Repository());
    await _fillValid(tester);

    await _tapSend(tester);
    await tester.pumpAndSettle();

    final focus = FocusManager.instance.primaryFocus!;
    expect(
      find.descendant(
        of: find.byWidget(focus.context!.widget),
        matching: find.text('Message sent.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the minimum length is part of the validation message', (
    tester,
  ) async {
    await _pump(tester, _Repository());
    await tester.enterText(_field('Message'), 'short');

    await _tapSend(tester);

    expect(find.text('Please write at least 10 characters.'), findsOneWidget);
  });

  testWidgets('a failure keeps the text and offers the mailto fallback', (
    tester,
  ) async {
    final repository = _Repository(fail: true);
    await _pump(tester, repository);
    await _fillValid(tester);

    await _tapSend(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be sent'), findsOneWidget);
    expect(_mailtoLink('Remote%20Flutter%20opportunity'), findsWidgets);
    expect(find.text('EMAIL ME DIRECTLY'), findsOneWidget);
    expect(
      tester.widget<TextField>(_field('Message')).controller?.text,
      'We have a remote Flutter role for you.',
    );

    await _tapSend(tester);
    await tester.pumpAndSettle();
    expect(repository.sent, hasLength(2));
  });

  testWidgets('the failure is announced', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _Repository(fail: true));
    await _fillValid(tester);

    await _tapSend(tester);
    await tester.pumpAndSettle();

    final status = tester.getSemantics(
      find.textContaining('could not be sent'),
    );
    expect(status.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('the email app link is a real link with an encoded subject', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _Repository());

    expect(find.text('Prefer your own email app?'), findsOneWidget);
    expect(_mailtoLink('Remote%20Flutter%20opportunity'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('OPEN IT')),
      isSemantics(label: 'Open it', isLink: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('the email app link is localized in Portuguese', (tester) async {
    await _pump(tester, _Repository(), locale: AppLocale.pt);

    expect(find.text('Prefere usar seu app de email?'), findsOneWidget);
    expect(_mailtoLink('Oportunidade%20Flutter%20remota'), findsOneWidget);
  });

  testWidgets('the honeypot is hidden, unfocusable and out of semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _Repository());

    final honeypot = find.byKey(
      ContactSection.honeypotKey,
      skipOffstage: false,
    );
    expect(honeypot, findsOneWidget);
    expect(find.byKey(ContactSection.honeypotKey), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ExcludeSemantics, skipOffstage: false),
        matching: honeypot,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ExcludeFocus, skipOffstage: false),
        matching: honeypot,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('honeypot|website', caseSensitive: false)),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('a filled honeypot reaches sent without calling the repository', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);
    await _fillValid(tester);
    tester
            .widget<TextField>(
              find.byKey(ContactSection.honeypotKey, skipOffstage: false),
            )
            .controller!
            .text =
        'http://spam.example';

    await _tapSend(tester);
    await tester.pumpAndSettle();

    expect(repository.sent, isEmpty);
    expect(find.text('Message sent.'), findsOneWidget);
  });

  testWidgets('fields and buttons are at least 48 px tall', (tester) async {
    await _pump(tester, _Repository());

    for (final label in ['Name', 'Email', 'Company (optional)', 'Message']) {
      expect(
        tester.getSize(_field(label)).height,
        greaterThanOrEqualTo(48),
        reason: label,
      );
    }
    expect(
      tester.getSize(find.byType(LsButton).first).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('OPEN IT'),
                  matching: find.byType(ConstrainedBox),
                )
                .first,
          )
          .height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('stacks the form under the heading on a phone', (tester) async {
    await _pump(tester, _Repository(), width: 390);

    final heading = tester.getTopLeft(find.textContaining('Hiring a'));
    final form = tester.getTopLeft(_field('Name'));
    expect(form.dy, greaterThan(heading.dy));
    expect(form.dx, tester.getTopLeft(find.textContaining('Hiring a')).dx);
  });

  testWidgets('puts the form beside the heading on desktop', (tester) async {
    await _pump(tester, _Repository());

    final heading = tester.getTopLeft(find.textContaining('Hiring a'));
    final form = tester.getTopLeft(_field('Name'));
    expect(form.dx, greaterThan(heading.dx + 300));
  });

  for (final locale in AppLocale.values) {
    for (final width in [360.0, 390.0, 768.0, 1440.0]) {
      for (final failed in [false, true]) {
        testWidgets('lays out without overflow at ${width.toInt()} px in '
            '${locale.name}${failed ? ' when failed' : ''}', (tester) async {
          await _pump(
            tester,
            _Repository(fail: true),
            width: width,
            locale: locale,
            cvAvailable: true,
          );
          if (failed) {
            final labels = locale == AppLocale.en
                ? ['Name', 'Email', 'Message']
                : ['Nome', 'Email', 'Mensagem'];
            await tester.enterText(_field(labels[0]), 'Ana Recruiter');
            await tester.enterText(_field(labels[1]), 'ana@example.com');
            await tester.enterText(
              _field(labels[2]),
              'We have a remote Flutter role for you.',
            );
            await tester.tap(
              find.text(
                locale == AppLocale.en ? 'Send message' : 'Enviar mensagem',
              ),
            );
            await tester.pumpAndSettle();
          }

          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
