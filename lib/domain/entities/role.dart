class Role {
  const Role({
    required this.period,
    required this.current,
    required this.company,
    required this.title,
    required this.summary,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    period: json['period'] as String,
    current: json['current'] as bool,
    company: json['company'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
  );

  final String period;
  final bool current;
  final String company;
  final String title;
  final String summary;
}
