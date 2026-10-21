import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';

class ContactSendException implements Exception {
  const ContactSendException(this.reason);

  final String reason;

  @override
  String toString() => 'ContactSendException: $reason';
}

abstract interface class ContactRepository {
  Future<void> send(ContactMessage message);
}
