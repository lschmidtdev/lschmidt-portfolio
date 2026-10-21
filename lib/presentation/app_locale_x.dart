import 'dart:ui' show Locale;

import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';

extension AppLocaleX on AppLocale {
  String get htmlLang => switch (this) {
    AppLocale.en => 'en',
    AppLocale.pt => 'pt-BR',
  };

  Locale get flutterLocale => switch (this) {
    AppLocale.en => const Locale('en'),
    AppLocale.pt => const Locale('pt', 'BR'),
  };
}
