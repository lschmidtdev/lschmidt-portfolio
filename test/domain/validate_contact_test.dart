import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/domain/usecases/validate_contact.dart';

void main() {
  test('the name is required', () {
    expect(ValidateContact.name(null), ContactFieldError.nameRequired);
    expect(ValidateContact.name('   '), ContactFieldError.nameRequired);
    expect(ValidateContact.name('Ana'), isNull);
  });

  test('the email must look like an address', () {
    for (final bad in [
      null,
      '',
      'ana',
      'ana@',
      'ana@x',
      '@x.com',
      'a b@x.com',
    ]) {
      expect(
        ValidateContact.email(bad),
        ContactFieldError.emailInvalid,
        reason: '$bad',
      );
    }
    expect(ValidateContact.email(' ana@example.com '), isNull);
  });

  test('the message needs at least 10 characters once trimmed', () {
    expect(ValidateContact.message(null), ContactFieldError.messageTooShort);
    expect(
      ValidateContact.message('  short   '),
      ContactFieldError.messageTooShort,
    );
    expect(
      ValidateContact.message('123456789'),
      ContactFieldError.messageTooShort,
    );
    expect(ValidateContact.message('1234567890'), isNull);
  });
}
