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
}
