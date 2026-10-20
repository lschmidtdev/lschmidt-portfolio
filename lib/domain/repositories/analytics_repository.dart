enum AnalyticsEvent {
  cvDownload('cv_download'),
  contactFormSent('contact_form_sent'),
  emailAppOpened('email_app_opened'),
  playStoreClick('play_store_click');

  const AnalyticsEvent(this.eventName);

  final String eventName;
}

abstract interface class AnalyticsRepository {
  void track(AnalyticsEvent event);
}

class NoopAnalyticsRepository implements AnalyticsRepository {
  const NoopAnalyticsRepository();

  @override
  void track(AnalyticsEvent event) {}
}
