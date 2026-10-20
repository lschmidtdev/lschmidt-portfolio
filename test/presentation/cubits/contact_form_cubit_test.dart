import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/analytics_repository.dart';
import 'package:lschmidt_portfolio/domain/repositories/contact_repository.dart';
import 'package:lschmidt_portfolio/presentation/cubits/contact_form_cubit.dart';

import '../../helpers/recording_analytics.dart';

class _Repository implements ContactRepository {
  _Repository({this.error, this.gate});

  final Object? error;
  final Completer<void>? gate;
  final sent = <ContactMessage>[];

  @override
  Future<void> send(ContactMessage message) async {
    sent.add(message);
    await gate?.future;
    if (error != null) throw error!;
  }
}

const _message = ContactMessage(
  name: 'Ana',
  email: 'ana@example.com',
  message: 'A message long enough.',
);

const _spam = ContactMessage(
  name: 'Bot',
  email: 'bot@example.com',
  message: 'Buy things right now please.',
  honeypot: 'http://spam.example',
);

void main() {
  late _Repository repository;

  blocTest<ContactFormCubit, ContactFormState>(
    'submit goes through sending to sent',
    setUp: () => repository = _Repository(),
    build: () => ContactFormCubit(repository),
    act: (cubit) => cubit.submit(_message),
    expect: () => [isA<ContactSending>(), isA<ContactSent>()],
    verify: (_) => expect(repository.sent, [_message]),
  );

  blocTest<ContactFormCubit, ContactFormState>(
    'a filled honeypot resolves to sent without calling the repository',
    setUp: () => repository = _Repository(),
    build: () => ContactFormCubit(repository),
    act: (cubit) => cubit.submit(_spam),
    expect: () => [isA<ContactSent>()],
    verify: (_) => expect(repository.sent, isEmpty),
  );

  group('analytics', () {
    test('a sent message is tracked once, after the repository call', () async {
      final analytics = RecordingAnalytics();
      repository = _Repository();
      final cubit = ContactFormCubit(repository, analytics: analytics);

      await cubit.submit(_message);

      expect(analytics.events, [AnalyticsEvent.contactFormSent]);
      await cubit.close();
    });

    test('a failed send is not tracked', () async {
      final analytics = RecordingAnalytics();
      repository = _Repository(error: const ContactSendException('down'));
      final cubit = ContactFormCubit(repository, analytics: analytics);

      await cubit.submit(_message);

      expect(cubit.state, isA<ContactFailed>());
      expect(analytics.events, isEmpty);
      await cubit.close();
    });

    test('the honeypot path is not tracked', () async {
      final analytics = RecordingAnalytics();
      repository = _Repository();
      final cubit = ContactFormCubit(repository, analytics: analytics);

      await cubit.submit(_spam);

      expect(cubit.state, isA<ContactSent>());
      expect(analytics.events, isEmpty);
      await cubit.close();
    });
  });

  test('submit while sending is ignored', () async {
    final gate = Completer<void>();
    repository = _Repository(gate: gate);
    final cubit = ContactFormCubit(repository);

    final first = cubit.submit(_message);
    await cubit.submit(_message);
    gate.complete();
    await first;

    expect(repository.sent, hasLength(1));
    expect(cubit.state, isA<ContactSent>());
    await cubit.close();
  });

  for (final (name, error) in [
    ('a send exception', const ContactSendException('success:false')),
    ('a timeout', TimeoutException('slow')),
    ('an unexpected error', StateError('boom')),
  ]) {
    blocTest<ContactFormCubit, ContactFormState>(
      '$name ends in failed and keeps the message',
      setUp: () => repository = _Repository(error: error),
      build: () => ContactFormCubit(repository),
      act: (cubit) => cubit.submit(_message),
      expect: () => [
        isA<ContactSending>(),
        isA<ContactFailed>().having((s) => s.message, 'message', _message),
      ],
    );
  }

  blocTest<ContactFormCubit, ContactFormState>(
    'submit can be retried after a failure',
    setUp: () =>
        repository = _Repository(error: const ContactSendException('x')),
    build: () => ContactFormCubit(repository),
    act: (cubit) async {
      await cubit.submit(_message);
      await cubit.submit(_message);
    },
    expect: () => [
      isA<ContactSending>(),
      isA<ContactFailed>(),
      isA<ContactSending>(),
      isA<ContactFailed>(),
    ],
    verify: (_) => expect(repository.sent, hasLength(2)),
  );

  blocTest<ContactFormCubit, ContactFormState>(
    'reset returns to idle',
    setUp: () => repository = _Repository(),
    build: () => ContactFormCubit(repository),
    act: (cubit) async {
      await cubit.submit(_message);
      cubit.reset();
    },
    skip: 2,
    expect: () => [isA<ContactIdle>()],
  );
}
