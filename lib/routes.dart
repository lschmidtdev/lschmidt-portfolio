import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';

String? redirectFor(String path) {
  if (path == AppLocale.en.path || path == AppLocale.pt.path) return null;
  if (path == '${AppLocale.pt.path}/') return AppLocale.pt.path;
  return AppLocale.en.path;
}

AppLocale localeForPath(String path) =>
    (redirectFor(path) ?? path) == AppLocale.pt.path
    ? AppLocale.pt
    : AppLocale.en;
