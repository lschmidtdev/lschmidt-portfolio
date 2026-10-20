import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/contact_repository.dart';

class Web3FormsContactRepository implements ContactRepository {
  Web3FormsContactRepository(
    this._client, {
    required String accessKey,
    Duration timeout = const Duration(seconds: 10),
  }) : _accessKey = accessKey,
       _timeout = timeout;

  static final endpoint = Uri.parse('https://api.web3forms.com/submit');

  final http.Client _client;
  final String _accessKey;
  final Duration _timeout;

  @override
  Future<void> send(ContactMessage message) async {
    if (_accessKey.isEmpty) {
      throw const ContactSendException('no access key configured');
    }
    final company = message.company?.trim() ?? '';
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'access_key': _accessKey,
              'subject': 'Portfolio contact from ${message.name.trim()}',
              'name': message.name.trim(),
              'email': message.email.trim(),
              if (company.isNotEmpty) 'company': company,
              'message': message.message.trim(),
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ContactSendException('timeout');
    } on http.ClientException catch (e) {
      throw ContactSendException(e.message);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContactSendException('status ${response.statusCode}');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ContactSendException('unreadable response');
    }
    if (decoded is! Map || decoded['success'] != true) {
      throw const ContactSendException('rejected');
    }
  }
}
