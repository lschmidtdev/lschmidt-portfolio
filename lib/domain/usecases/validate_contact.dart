enum ContactFieldError { nameRequired, emailInvalid, messageTooShort }

abstract final class ValidateContact {
  static const minMessageLength = 10;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static ContactFieldError? name(String? value) =>
      (value ?? '').trim().isEmpty ? ContactFieldError.nameRequired : null;

  static ContactFieldError? email(String? value) =>
      _email.hasMatch((value ?? '').trim())
      ? null
      : ContactFieldError.emailInvalid;

  static ContactFieldError? message(String? value) =>
      (value ?? '').trim().length < minMessageLength
      ? ContactFieldError.messageTooShort
      : null;
}
