import 'currently_item.dart';
import 'education.dart';
import 'metric.dart';
import 'profile.dart';
import 'project.dart';
import 'role.dart';
import 'skill_group.dart';

class PortfolioContent {
  const PortfolioContent({
    required this.profile,
    required this.currently,
    required this.metrics,
    required this.projects,
    required this.roles,
    required this.skillGroups,
    required this.education,
    required this.languages,
  });

  factory PortfolioContent.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        List.unmodifiable(
          (json[key] as List).map((e) => parse(e as Map<String, dynamic>)),
        );
    return PortfolioContent(
      profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
      currently: list('currently', CurrentlyItem.fromJson),
      metrics: list('metrics', Metric.fromJson),
      projects: list('projects', Project.fromJson),
      roles: list('roles', Role.fromJson),
      skillGroups: list('skillGroups', SkillGroup.fromJson),
      education: list('education', Education.fromJson),
      languages: List.unmodifiable((json['languages'] as List).cast<String>()),
    );
  }

  final Profile profile;
  final List<CurrentlyItem> currently;
  final List<Metric> metrics;
  final List<Project> projects;
  final List<Role> roles;
  final List<SkillGroup> skillGroups;
  final List<Education> education;
  final List<String> languages;
}
