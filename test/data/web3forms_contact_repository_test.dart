import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lschmidt_portfolio/data/repositories/web3forms_contact_repository.dart';
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/contact_repository.dart';

const _message = ContactMessage(
  name: 'Ana Recruiter',
  email: 'ana@example.com',
  company: 'Acme',
  message: 'We have a remote Flutter role for you.',
);

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Web3FormsContactRepository _repository(
  Future<http.Response> Function(http.Request) handler, {
  String accessKey = 'key-123',
  Duration timeout = const Duration(seconds: 10),
}) => Web3FormsContactRepository(
  MockClient(handler),
  accessKey: accessKey,
  timeout: timeout,
);

void main() {
  test('posts the form as JSON to the Web3Forms endpoint', () async {
    late http.Request request;
    final repository = _repository((r) async {
      request = r;
      return _json(200, {'success': true});
    });

    await repository.send(_message);

    expect(request.method, 'POST');
    expect(request.url.toString(), 'https://api.web3forms.com/submit');
    expect(request.headers['Content-Type'], contains('application/json'));
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['access_key'], 'key-123');
    expect(body['name'], 'Ana Recruiter');
    expect(body['email'], 'ana@example.com');
    expect(body['message'], 'We have a remote Flutter role for you.');
    expect(body['company'], 'Acme');
    expect(body['subject'], isA<String>());
    expect(body['subject'] as String, isNotEmpty);
  });

  test('omits the company when it is empty', () async {
    late Map<String, dynamic> body;
    final repository = _repository((r) async {
      body = jsonDecode(r.body) as Map<String, dynamic>;
      return _json(200, {'success': true});
    });

    await repository.send(
      const ContactMessage(
        name: 'Ana',
        email: 'ana@example.com',
        message: 'A message long enough.',
      ),
    );

    expect(body.containsKey('company'), isFalse);
  });

  test('an empty access key fails fast without any network call', () async {
    var calls = 0;
    final repository = _repository((r) async {
      calls++;
      return _json(200, {'success': true});
    }, accessKey: '');

    await expectLater(
      repository.send(_message),
      throwsA(isA<ContactSendException>()),
    );
    expect(calls, 0);
  });

  test('success:false is a failure', () async {
    final repository = _repository((r) async => _json(200, {'success': false}));

    await expectLater(
      repository.send(_message),
      throwsA(isA<ContactSendException>()),
    );
  });

  test('an HTTP 500 is a failure', () async {
    final repository = _repository((r) async => _json(500, {'success': true}));

    await expectLater(
      repository.send(_message),
      throwsA(isA<ContactSendException>()),
    );
  });

  test('a body that is not JSON is a failure', () async {
    final repository = _repository((r) async => http.Response('<html>', 200));

    await expectLater(
      repository.send(_message),
      throwsA(isA<ContactSendException>()),
    );
  });

  test('a client error is a failure', () async {
    final repository = _repository(
      (r) async => throw http.ClientException('offline'),
    );

    await expectLater(
      repository.send(_message),
      throwsA(isA<ContactSendException>()),
    );
  });

  test('a timeout is a failure', () async {
    final never = Completer<http.Response>();
    final repository = _repository(
      (r) => never.future,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      repository.send(_message),
      throwsA(isA<ContactSendException>()),
    );
  });
}
