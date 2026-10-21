import 'package:bloc/bloc.dart';
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/analytics_repository.dart';
import 'package:lschmidt_portfolio/domain/repositories/contact_repository.dart';

sealed class ContactFormState {
  const ContactFormState();
}

class ContactIdle extends ContactFormState {
  const ContactIdle();
}

class ContactSending extends ContactFormState {
  const ContactSending();
}

class ContactSent extends ContactFormState {
  const ContactSent();
}

class ContactFailed extends ContactFormState {
  const ContactFailed(this.message);

  final ContactMessage message;
}

class ContactFormCubit extends Cubit<ContactFormState> {
  ContactFormCubit(
    this._repository, {
    AnalyticsRepository analytics = const NoopAnalyticsRepository(),
  }) : _analytics = analytics,
       super(const ContactIdle());

  final ContactRepository _repository;
  final AnalyticsRepository _analytics;

  Future<void> submit(ContactMessage message) async {
    if (state is ContactSending) return;
    if (message.honeypot.isNotEmpty) {
      emit(const ContactSent());
      return;
    }
    emit(const ContactSending());
    try {
      await _repository.send(message);
    } on Object {
      if (!isClosed) emit(ContactFailed(message));
      return;
    }
    if (!isClosed) emit(const ContactSent());
    try {
      _analytics.track(AnalyticsEvent.contactFormSent);
    } on Object {
      return;
    }
  }

  void reset() => emit(const ContactIdle());
}
