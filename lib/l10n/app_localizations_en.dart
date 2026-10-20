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
}
