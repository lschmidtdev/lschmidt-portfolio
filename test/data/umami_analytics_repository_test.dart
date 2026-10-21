import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/data/repositories/umami_analytics_repository.dart';
import 'package:lschmidt_portfolio/data/sources/umami_bridge.dart';
import 'package:lschmidt_portfolio/domain/repositories/analytics_repository.dart';

void main() {
  test('the four events keep their wire names', () {
    expect(
      {for (final e in AnalyticsEvent.values) e.name: e.eventName},
      {
        'cvDownload': 'cv_download',
        'contactFormSent': 'contact_form_sent',
        'emailAppOpened': 'email_app_opened',
        'playStoreClick': 'play_store_click',
      },
    );
  });

  test('track sends the event name and nothing else, once', () {
    final sent = <String>[];
    UmamiAnalyticsRepository(
      send: sent.add,
    ).track(AnalyticsEvent.contactFormSent);
    expect(sent, ['contact_form_sent']);
  });

  test('track is synchronous and swallows a failing bridge', () {
    final repository = UmamiAnalyticsRepository(
      send: (_) => throw StateError('blocked'),
    );
    expect(() => repository.track(AnalyticsEvent.cvDownload), returnsNormally);
  });

  test('the VM bridge does nothing and throws nothing', () {
    expect(() => umamiTrack('cv_download'), returnsNormally);
    expect(
      () => const UmamiAnalyticsRepository().track(AnalyticsEvent.cvDownload),
      returnsNormally,
    );
  });

  test('the noop repository ignores every event', () {
    for (final event in AnalyticsEvent.values) {
      expect(
        () => const NoopAnalyticsRepository().track(event),
        returnsNormally,
      );
    }
  });
}
