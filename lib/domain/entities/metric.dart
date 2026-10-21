class Metric {
  const Metric({required this.value, required this.label, this.unit});

  factory Metric.fromJson(Map<String, dynamic> json) => Metric(
    value: json['value'] as String,
    unit: json['unit'] as String?,
    label: json['label'] as String,
  );

  final String value;
  final String? unit;
  final String label;
}
