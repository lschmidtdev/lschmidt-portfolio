import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Page title and social title of the shell (HTML title, og:title)
  ///
  /// In en, this message translates to:
  /// **'Lucas Schmidt — Mobile Engineer (Flutter)'**
  String get metaTitle;

  /// Meta description and social description of the shell, at most 160 characters
  ///
  /// In en, this message translates to:
  /// **'Mobile engineer building production Flutter apps since 2020. Open to remote roles.'**
  String get metaDescription;

  /// Heading of the no-JavaScript fallback
  ///
  /// In en, this message translates to:
  /// **'Lucas Schmidt, Mobile Engineer (Flutter)'**
  String get fallbackTitle;

  /// Text of the no-JavaScript fallback, includes the email address
  ///
  /// In en, this message translates to:
  /// **'I build production Flutter apps and I am open to remote roles. This page needs JavaScript to load; you can reach me at lschmidt.dev@gmail.com.'**
  String get fallbackBody;

  /// Accessible name of the main navigation landmark
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get navMainLabel;

  /// Header link to the Selected work section
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get navWork;

  /// Header link to the Experience section
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get navExperience;

  /// Header link to the Skills section
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get navSkills;

  /// Header link to the Contact section
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get navContact;

  /// Accessible name of the EN/PT switch
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageGroupLabel;

  /// Accessible name of the EN button
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishLabel;

  /// Accessible name of the PT button
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortugueseLabel;

  /// Accessible name of the icon-only theme button
  ///
  /// In en, this message translates to:
  /// **'Toggle light or dark theme'**
  String get themeToggleLabel;

  /// Hero primary button, links to the PDF
  ///
  /// In en, this message translates to:
  /// **'Download CV (PDF)'**
  String get heroDownloadCv;

  /// Hero ghost button, scrolls to the Contact section
  ///
  /// In en, this message translates to:
  /// **'Email me'**
  String get heroEmailMe;

  /// Title of the Currently card
  ///
  /// In en, this message translates to:
  /// **'Currently'**
  String get currentlyTitle;

  /// Availability badge of the Currently card
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get currentlyAvailable;

  /// Accessible name of the results strip
  ///
  /// In en, this message translates to:
  /// **'Selected results'**
  String get resultsLabel;

  /// Heading of the Selected work section
  ///
  /// In en, this message translates to:
  /// **'Selected work'**
  String get workTitle;

  /// Project count and period next to the Selected work heading
  ///
  /// In en, this message translates to:
  /// **'{count} projects · 2023 — 2026'**
  String workCount(String count);

  /// Button linking to the Play Store listing of a project
  ///
  /// In en, this message translates to:
  /// **'Get it on Google Play'**
  String get workPlayStore;

  /// Heading of the Experience section
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceTitle;

  /// Period shown next to the Experience heading
  ///
  /// In en, this message translates to:
  /// **'2021 — now'**
  String get experienceRange;

  /// Heading of the Skills section
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillsTitle;

  /// Label of the education line under the skill groups
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get skillsEducation;

  /// Label of the languages line under the skill groups
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get skillsLanguages;

  /// Copyright line of the footer
  ///
  /// In en, this message translates to:
  /// **'© 2026 {name}'**
  String footerCopyright(String name);

  /// Footer note about the technology
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter Web'**
  String get footerBuilt;

  /// Footer note with the date the CV was last updated
  ///
  /// In en, this message translates to:
  /// **'CV updated {date}'**
  String footerCvUpdated(String date);

  /// Eyebrow of the Contact section
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactEyebrow;

  /// Contact heading; the text between asterisks gets the accent colour
  ///
  /// In en, this message translates to:
  /// **'Hiring a\n*Flutter* engineer?'**
  String get contactHeading;

  /// Button linking to the LinkedIn profile
  ///
  /// In en, this message translates to:
  /// **'LinkedIn ↗'**
  String get contactLinkedIn;

  /// Button linking to the GitHub profile
  ///
  /// In en, this message translates to:
  /// **'GitHub ↗'**
  String get contactGitHub;

  /// Button linking to the CV PDF
  ///
  /// In en, this message translates to:
  /// **'CV · PDF ↓'**
  String get contactCv;

  /// Accessible name of the contact form
  ///
  /// In en, this message translates to:
  /// **'Contact form'**
  String get contactFormLabel;

  /// Label of the name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactNameLabel;

  /// Label of the email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// Label of the optional company field
  ///
  /// In en, this message translates to:
  /// **'Company (optional)'**
  String get contactCompanyLabel;

  /// Label of the message field
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactMessageLabel;

  /// Validation error for an empty name
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get contactErrorNameRequired;

  /// Validation error for an invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get contactErrorEmailInvalid;

  /// Validation error for a short message
  ///
  /// In en, this message translates to:
  /// **'Please write at least 10 characters.'**
  String get contactErrorMessageTooShort;

  /// Submit button of the contact form
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get contactSend;

  /// Submit button text and status while the message is being sent
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get contactSending;

  /// Heading shown after the message was sent
  ///
  /// In en, this message translates to:
  /// **'Message sent.'**
  String get contactSentTitle;

  /// Text shown after the message was sent
  ///
  /// In en, this message translates to:
  /// **'Thanks for reaching out. I will reply by email.'**
  String get contactSentBody;

  /// Button that shows the form again after a message was sent
  ///
  /// In en, this message translates to:
  /// **'Send another message'**
  String get contactSendAnother;

  /// Text shown when sending failed
  ///
  /// In en, this message translates to:
  /// **'Your message could not be sent. It is still in the form, so you can try again or email me directly.'**
  String get contactFailedMessage;

  /// Link to the email app shown when sending failed
  ///
  /// In en, this message translates to:
  /// **'Email me directly'**
  String get contactFailedMailto;

  /// Prompt before the link that opens the email app
  ///
  /// In en, this message translates to:
  /// **'Prefer your own email app?'**
  String get contactEmailAppPrompt;

  /// Link that opens the email app
  ///
  /// In en, this message translates to:
  /// **'Open it'**
  String get contactEmailAppAction;

  /// Subject of the message prepared by the email app link
  ///
  /// In en, this message translates to:
  /// **'Remote Flutter opportunity'**
  String get contactMailSubject;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
