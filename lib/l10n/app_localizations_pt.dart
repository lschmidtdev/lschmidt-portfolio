// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get metaTitle => 'Lucas Schmidt — Engenheiro Mobile (Flutter)';

  @override
  String get metaDescription =>
      'Engenheiro mobile que desenvolve apps Flutter em produção desde 2020. Aberto a vagas remotas.';

  @override
  String get fallbackTitle => 'Lucas Schmidt, Engenheiro Mobile (Flutter)';

  @override
  String get fallbackBody =>
      'Eu desenvolvo apps Flutter em produção e estou aberto a vagas remotas. Esta página precisa de JavaScript para carregar; você pode falar comigo em lschmidt.dev@gmail.com.';

  @override
  String get navMainLabel => 'Principal';

  @override
  String get navWork => 'Trabalho';

  @override
  String get navExperience => 'Experiência';

  @override
  String get navSkills => 'Habilidades';

  @override
  String get navContact => 'Contato';

  @override
  String get languageGroupLabel => 'Idioma';

  @override
  String get languageEnglishLabel => 'English';

  @override
  String get languagePortugueseLabel => 'Português';

  @override
  String get themeToggleLabel => 'Alternar tema claro ou escuro';

  @override
  String get heroDownloadCv => 'Baixar CV (PDF)';

  @override
  String get heroEmailMe => 'Fale comigo';

  @override
  String get currentlyTitle => 'Atualmente';

  @override
  String get currentlyAvailable => 'Disponível';

  @override
  String get resultsLabel => 'Resultados em destaque';

  @override
  String get workTitle => 'Trabalhos selecionados';

  @override
  String workCount(String count) {
    return '$count projetos · 2023 — 2026';
  }

  @override
  String get workPlayStore => 'Disponível no Google Play';
}
