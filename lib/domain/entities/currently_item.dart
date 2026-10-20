class CurrentlyItem {
  const CurrentlyItem({required this.label, required this.value, this.date});

  factory CurrentlyItem.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String?;
    return CurrentlyItem(
      label: json['label'] as String,
      value: json['value'] as String,
      date: date == null ? null : DateTime.parse(date),
    );
  }

  final String label;
  final String value;
  final DateTime? date;
}
