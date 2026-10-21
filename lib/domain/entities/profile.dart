class Profile {
  const Profile({
    required this.name,
    required this.role,
    required this.summary,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'] as String,
    role: json['role'] as String,
    summary: json['summary'] as String,
  );

  final String name;
  final String role;
  final String summary;
}
