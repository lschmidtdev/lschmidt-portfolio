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

  @override
  String get experienceTitle => 'Experiência';

  @override
  String get experienceRange => '2021 — atual';

  @override
  String get skillsTitle => 'Habilidades';

  @override
  String get skillsEducation => 'Formação';

  @override
  String get skillsLanguages => 'Idiomas';

  @override
  String footerCopyright(String name) {
    return '© 2026 $name';
  }

  @override
  String get footerBuilt => 'Feito com Flutter Web';

  @override
  String footerCvUpdated(String date) {
    return 'CV atualizado em $date';
  }

  @override
  String get contactEyebrow => 'Contato';

  @override
  String get contactHeading => 'Procurando um\nengenheiro *Flutter*?';

  @override
  String get contactLinkedIn => 'LinkedIn ↗';

  @override
  String get contactGitHub => 'GitHub ↗';

  @override
  String get contactCv => 'CV · PDF ↓';

  @override
  String get contactFormLabel => 'Formulário de contato';

  @override
  String get contactNameLabel => 'Nome';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactCompanyLabel => 'Empresa (opcional)';

  @override
  String get contactMessageLabel => 'Mensagem';

  @override
  String get contactErrorNameRequired => 'Informe seu nome.';

  @override
  String get contactErrorEmailInvalid => 'Informe um email válido.';

  @override
  String get contactErrorMessageTooShort => 'Escreva pelo menos 10 caracteres.';

  @override
  String get contactSend => 'Enviar mensagem';

  @override
  String get contactSending => 'Enviando…';

  @override
  String get contactSentTitle => 'Mensagem enviada.';

  @override
  String get contactSentBody => 'Obrigado pelo contato. Respondo por email.';

  @override
  String get contactSendAnother => 'Enviar outra mensagem';

  @override
  String get contactFailedMessage =>
      'Não foi possível enviar sua mensagem. Ela continua no formulário, então você pode tentar de novo ou escrever direto para mim.';

  @override
  String get contactFailedMailto => 'Escreva direto para mim';

  @override
  String get contactEmailAppPrompt => 'Prefere usar seu app de email?';

  @override
  String get contactEmailAppAction => 'Abrir';

  @override
  String get contactMailSubject => 'Oportunidade Flutter remota';
}
