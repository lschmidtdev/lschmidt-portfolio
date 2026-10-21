import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_link.dart';
import 'package:lschmidt_portfolio/core/widgets/reveal_on_scroll.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/contact_message.dart';
import 'package:lschmidt_portfolio/domain/repositories/analytics_repository.dart';
import 'package:lschmidt_portfolio/domain/usecases/validate_contact.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:lschmidt_portfolio/presentation/cubits/contact_form_cubit.dart';
import 'package:lschmidt_portfolio/presentation/sections/hero.dart';
import 'package:url_launcher/link.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({
    super.key,
    required this.locale,
    this.cvAvailable = SiteConfig.cvAvailable,
  });

  static const honeypotKey = ValueKey<String>('contact-honeypot');
  static const sideBySideWidth = 900.0;
  static const columnGap = 64.0;
  static const formMaxWidth = 520.0;
  static const fieldGap = 16.0;

  final AppLocale locale;
  final bool cvAvailable;

  static Uri mailtoWithSubject(String subject) => Uri.parse(
    'mailto:${SiteConfig.email}?subject=${Uri.encodeComponent(subject)}',
  );

  static Uri mailtoWithMessage(String subject, ContactMessage message) {
    final signature = [
      message.name,
      ?message.company,
    ].where((part) => part.isNotEmpty).join(' · ');
    final body = signature.isEmpty
        ? message.message
        : '${message.message}\n\n$signature';
    return Uri.parse(
      '${mailtoWithSubject(subject)}&body=${Uri.encodeComponent(body)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SectionShell(
      id: SectionId.contact,
      top: (width * 0.11).clamp(80.0, 160.0),
      bottom: (width * 0.08).clamp(64.0, 112.0),
      child: RevealOnScroll(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= sideBySideWidth;
            final intro = _Intro(
              locale: locale,
              cvAvailable: cvAvailable,
              sideBySide: sideBySide,
            );
            const form = _ContactForm();
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: intro),
                  const SizedBox(width: columnGap),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: formMaxWidth,
                        ),
                        child: form,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                intro,
                const SizedBox(height: LsSpacing.s16),
                form,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.locale,
    required this.cvAvailable,
    required this.sideBySide,
  });

  final AppLocale locale;
  final bool cvAvailable;
  final bool sideBySide;

  List<InlineSpan> _heading(String text, TextStyle accent) {
    final parts = text.split('*');
    return [
      for (final (i, part) in parts.indexed)
        TextSpan(text: part, style: i.isOdd ? accent : null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final size = (width * 0.07).clamp(44.0, sideBySide ? 64.0 : 80.0);
    final headingStyle = LsType.h2.copyWith(
      fontSize: size,
      height: 0.98,
      letterSpacing: -0.04 * size,
      color: colors.fg,
    );
    final emailSize = (width * 0.024).clamp(20.0, 30.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.contactEyebrow.toUpperCase(),
          style: LsType.eyebrow.copyWith(color: colors.fg3),
        ),
        const SizedBox(height: LsSpacing.s6),
        Semantics(
          header: true,
          label: l10n.contactHeading.replaceAll('*', ''),
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: _heading(
                l10n.contactHeading,
                headingStyle.copyWith(color: colors.accent),
              ),
            ),
            style: headingStyle,
          ),
        ),
        const SizedBox(height: LsSpacing.s8),
        LsLink(
          label: SiteConfig.email,
          href: SiteConfig.mailto,
          uppercase: false,
          style: LsType.body.copyWith(
            fontSize: emailSize,
            height: 1.3,
            letterSpacing: -0.01 * emailSize,
            decoration: TextDecoration.underline,
            decorationColor: colors.accent,
            decorationThickness: 2,
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: LsSpacing.s3,
          runSpacing: LsSpacing.s3,
          children: [
            LsButton.ghost(
              label: l10n.contactLinkedIn,
              href: Uri.parse(SiteConfig.linkedInUrl),
              target: LinkTarget.blank,
            ),
            LsButton.ghost(
              label: l10n.contactGitHub,
              href: Uri.parse(SiteConfig.gitHubUrl),
              target: LinkTarget.blank,
            ),
            if (cvAvailable)
              LsButton.ghost(
                label: l10n.contactCv,
                href: HeroSection.cvUri(locale),
                target: LinkTarget.blank,
              ),
          ],
        ),
      ],
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ContactFormCubit, ContactFormState>(
        builder: (context, state) =>
            state is ContactSent ? const _Sent() : _Fields(state: state),
      );
}

class _Sent extends StatefulWidget {
  const _Sent();

  @override
  State<_Sent> createState() => _SentState();
}

class _SentState extends State<_Sent> {
  final _heading = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _heading.requestFocus();
    });
  }

  @override
  void dispose() {
    _heading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Focus(
                focusNode: _heading,
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.contactSentTitle,
                    style: LsType.h3.copyWith(color: colors.fg),
                  ),
                ),
              ),
              const SizedBox(height: LsSpacing.s3),
              Text(
                l10n.contactSentBody,
                style: LsType.body.copyWith(color: colors.fg2),
              ),
            ],
          ),
        ),
        const SizedBox(height: LsSpacing.s6),
        LsLink(
          label: l10n.contactSendAnother,
          onPressed: context.read<ContactFormCubit>().reset,
        ),
      ],
    );
  }
}

class _Fields extends StatefulWidget {
  const _Fields({required this.state});

  final ContactFormState state;

  @override
  State<_Fields> createState() => _FieldsState();
}

class _FieldsState extends State<_Fields> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _company;
  late final TextEditingController _message;
  final _honeypot = TextEditingController();
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    final kept = widget.state is ContactFailed
        ? (widget.state as ContactFailed).message
        : null;
    _name = TextEditingController(text: kept?.name);
    _email = TextEditingController(text: kept?.email);
    _company = TextEditingController(text: kept?.company);
    _message = TextEditingController(text: kept?.message);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _company.dispose();
    _message.dispose();
    _honeypot.dispose();
    super.dispose();
  }

  String? _errorText(AppLocalizations l10n, ContactFieldError? error) =>
      switch (error) {
        null => null,
        ContactFieldError.nameRequired => l10n.contactErrorNameRequired,
        ContactFieldError.emailInvalid => l10n.contactErrorEmailInvalid,
        ContactFieldError.messageTooShort => l10n.contactErrorMessageTooShort(
          ValidateContact.minMessageLength,
        ),
      };

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final company = _company.text.trim();
    context.read<ContactFormCubit>().submit(
      ContactMessage(
        name: _name.text.trim(),
        email: _email.text.trim(),
        company: company.isEmpty ? null : company,
        message: _message.text.trim(),
        honeypot: _honeypot.text,
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String label) {
    final colors = LsColors.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: LsType.monoSm.copyWith(color: colors.fg3),
      floatingLabelStyle: LsType.monoSm.copyWith(color: colors.fg2),
      errorStyle: LsType.monoSm.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
      errorMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: LsSpacing.s4,
        vertical: LsSpacing.s4,
      ),
      enabledBorder: border(colors.line),
      focusedBorder: border(colors.accent, 2),
      errorBorder: border(Theme.of(context).colorScheme.error),
      focusedErrorBorder: border(Theme.of(context).colorScheme.error, 2),
      border: border(colors.line),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final sending = state is ContactSending;
    final failed = state is ContactFailed;
    final inputStyle = LsType.body.copyWith(color: colors.fg);
    final mailto = ContactSection.mailtoWithSubject(l10n.contactMailSubject);
    void trackEmailApp() => context.read<AnalyticsRepository>().track(
      AnalyticsEvent.emailAppOpened,
    );
    final autovalidate = _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled;
    return Semantics(
      container: true,
      label: l10n.contactFormLabel,
      child: Form(
        key: _formKey,
        autovalidateMode: autovalidate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              focusNode: SectionId.contact.focusIn(context),
              style: inputStyle,
              decoration: _decoration(context, l10n.contactNameLabel),
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              validator: (v) => _errorText(l10n, ValidateContact.name(v)),
            ),
            const SizedBox(height: ContactSection.fieldGap),
            TextFormField(
              controller: _email,
              style: inputStyle,
              decoration: _decoration(context, l10n.contactEmailLabel),
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => _errorText(l10n, ValidateContact.email(v)),
            ),
            const SizedBox(height: ContactSection.fieldGap),
            TextFormField(
              controller: _company,
              style: inputStyle,
              decoration: _decoration(context, l10n.contactCompanyLabel),
              autofillHints: const [AutofillHints.organizationName],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: ContactSection.fieldGap),
            TextFormField(
              controller: _message,
              style: inputStyle,
              decoration: _decoration(context, l10n.contactMessageLabel),
              keyboardType: TextInputType.multiline,
              minLines: 5,
              maxLines: 10,
              validator: (v) => _errorText(l10n, ValidateContact.message(v)),
            ),
            ExcludeSemantics(
              child: ExcludeFocus(
                child: Offstage(
                  child: TextField(
                    key: ContactSection.honeypotKey,
                    controller: _honeypot,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ContactSection.fieldGap),
            if (sending || failed) ...[
              Semantics(
                liveRegion: true,
                container: true,
                child: Text(
                  sending ? l10n.contactSending : l10n.contactFailedMessage,
                  style: LsType.bodySm.copyWith(color: colors.fg2),
                ),
              ),
              if (state is ContactFailed)
                LsLink(
                  label: l10n.contactFailedMailto,
                  href: ContactSection.mailtoWithMessage(
                    l10n.contactMailSubject,
                    state.message,
                  ),
                  onActivated: trackEmailApp,
                ),
              const SizedBox(height: LsSpacing.s3),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: LsButton.primary(
                label: l10n.contactSend,
                onPressed: sending ? null : _submit,
              ),
            ),
            const SizedBox(height: LsSpacing.s4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: LsSpacing.s2,
              children: [
                Text(
                  l10n.contactEmailAppPrompt,
                  style: LsType.bodySm.copyWith(color: colors.fg2),
                ),
                LsLink(
                  label: l10n.contactEmailAppAction,
                  href: mailto,
                  onActivated: trackEmailApp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
