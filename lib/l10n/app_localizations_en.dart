// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get metaTitle => 'Lucas Schmidt — Mobile Engineer (Flutter)';

  @override
  String get metaDescription =>
      'Mobile engineer building production Flutter apps since 2020. Open to remote roles.';

  @override
  String get fallbackTitle => 'Lucas Schmidt, Mobile Engineer (Flutter)';

  @override
  String get fallbackBody =>
      'I build production Flutter apps and I am open to remote roles. This page needs JavaScript to load; you can reach me at lschmidt.dev@gmail.com.';

  @override
  String get navMainLabel => 'Main';

  @override
  String get navWork => 'Work';

  @override
  String get navExperience => 'Experience';

  @override
  String get navSkills => 'Skills';

  @override
  String get navContact => 'Contact';

  @override
  String get languageGroupLabel => 'Language';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languagePortugueseLabel => 'Português';

  @override
  String get themeToggleLabel => 'Toggle light or dark theme';

  @override
  String get heroDownloadCv => 'Download CV (PDF)';

  @override
  String get heroEmailMe => 'Email me';

  @override
  String get currentlyTitle => 'Currently';

  @override
  String get currentlyAvailable => 'Available';

  @override
  String get resultsLabel => 'Selected results';

  @override
  String get workTitle => 'Selected work';

  @override
  String workCount(String count) {
    return '$count projects · 2023 — 2026';
  }

  @override
  String get workPlayStore => 'Get it on Google Play';

  @override
  String get experienceTitle => 'Experience';

  @override
  String get experienceRange => '2021 — now';

  @override
  String get skillsTitle => 'Skills';

  @override
  String get skillsEducation => 'Education';

  @override
  String get skillsLanguages => 'Languages';

  @override
  String footerCopyright(String name) {
    return '© 2026 $name';
  }

  @override
  String get footerBuilt => 'Built with Flutter Web';

  @override
  String footerCvUpdated(String date) {
    return 'CV updated $date';
  }

  @override
  String get contactEyebrow => 'Contact';

  @override
  String get contactHeading => 'Hiring a\n*Flutter* engineer?';

  @override
  String get contactLinkedIn => 'LinkedIn ↗';

  @override
  String get contactGitHub => 'GitHub ↗';

  @override
  String get contactCv => 'CV · PDF ↓';

  @override
  String get contactFormLabel => 'Contact form';

  @override
  String get contactNameLabel => 'Name';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactCompanyLabel => 'Company (optional)';

  @override
  String get contactMessageLabel => 'Message';

  @override
  String get contactErrorNameRequired => 'Please enter your name.';

  @override
  String get contactErrorEmailInvalid => 'Please enter a valid email address.';

  @override
  String get contactErrorMessageTooShort =>
      'Please write at least 10 characters.';

  @override
  String get contactSend => 'Send message';

  @override
  String get contactSending => 'Sending…';

  @override
  String get contactSentTitle => 'Message sent.';

  @override
  String get contactSentBody =>
      'Thanks for reaching out. I will reply by email.';

  @override
  String get contactSendAnother => 'Send another message';

  @override
  String get contactFailedMessage =>
      'Your message could not be sent. It is still in the form, so you can try again or email me directly.';

  @override
  String get contactFailedMailto => 'Email me directly';

  @override
  String get contactEmailAppPrompt => 'Prefer your own email app?';

  @override
  String get contactEmailAppAction => 'Open it';

  @override
  String get contactMailSubject => 'Remote Flutter opportunity';
}
