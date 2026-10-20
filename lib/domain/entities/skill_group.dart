class SkillGroup {
  const SkillGroup({
    required this.title,
    required this.items,
    required this.primary,
  });

  factory SkillGroup.fromJson(Map<String, dynamic> json) => SkillGroup(
    title: json['title'] as String,
    items: List.unmodifiable((json['items'] as List).cast<String>()),
    primary: json['primary'] as bool,
  );

  final String title;
  final List<String> items;
  final bool primary;
}
