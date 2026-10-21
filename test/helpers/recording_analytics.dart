import 'package:lschmidt_portfolio/domain/repositories/analytics_repository.dart';

class ThrowingAnalytics implements AnalyticsRepository {
  @override
  void track(AnalyticsEvent event) => throw StateError('blocked');
}

class RecordingAnalytics implements AnalyticsRepository {
  final events = <AnalyticsEvent>[];

  @override
  void track(AnalyticsEvent event) => events.add(event);
}
