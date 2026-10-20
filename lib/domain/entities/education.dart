class Education {
  const Education({
    required this.degree,
    required this.institution,
    required this.period,
  });

  factory Education.fromJson(Map<String, dynamic> json) => Education(
    degree: json['degree'] as String,
    institution: json['institution'] as String,
    period: json['period'] as String,
  );

  final String degree;
  final String institution;
  final String period;
}
