import 'metric.dart';

class Project {
  const Project({
    required this.id,
    required this.index,
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.tags,
    required this.stats,
    required this.headlineStats,
    required this.featured,
    this.footnote,
    this.playStoreUrl,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final playStoreUrl = json['playStoreUrl'] as String?;
    return Project(
      id: json['id'] as String,
      index: json['index'] as String,
      eyebrow: json['eyebrow'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      tags: List.unmodifiable((json['tags'] as List).cast<String>()),
      stats: List.unmodifiable(
        (json['stats'] as List).map(
          (e) => Metric.fromJson(e as Map<String, dynamic>),
        ),
      ),
      footnote: json['footnote'] as String?,
      playStoreUrl: playStoreUrl == null ? null : Uri.parse(playStoreUrl),
      headlineStats: json['headlineStats'] as bool,
      featured: json['featured'] as bool,
    );
  }

  final String id;
  final String index;
  final String eyebrow;
  final String title;
  final String summary;
  final List<String> tags;
  final List<Metric> stats;
  final String? footnote;
  final Uri? playStoreUrl;
  final bool headlineStats;
  final bool featured;
}
