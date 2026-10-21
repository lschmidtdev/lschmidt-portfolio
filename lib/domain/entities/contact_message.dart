class ContactMessage {
  const ContactMessage({
    required this.name,
    required this.email,
    this.company,
    required this.message,
    this.honeypot = '',
  });

  final String name;
  final String email;
  final String? company;
  final String message;
  final String honeypot;
}
