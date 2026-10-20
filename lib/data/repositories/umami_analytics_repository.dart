import 'package:lschmidt_portfolio/data/sources/umami_bridge.dart';
import 'package:lschmidt_portfolio/domain/repositories/analytics_repository.dart';

class UmamiAnalyticsRepository implements AnalyticsRepository {
  const UmamiAnalyticsRepository({
    void Function(String eventName) send = umamiTrack,
  }) : _send = send;

  final void Function(String eventName) _send;

  @override
  void track(AnalyticsEvent event) {
    try {
      _send(event.eventName);
    } on Object {
      return;
    }
  }
}
