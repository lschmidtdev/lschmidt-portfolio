import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/currently_item.dart';
import 'package:lschmidt_portfolio/domain/entities/profile.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:lschmidt_portfolio/presentation/sections/currently_card.dart';
import 'package:url_launcher/link.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.profile,
    required this.currently,
    required this.locale,
    required this.now,
    this.cvAvailable = SiteConfig.cvAvailable,
  });

  static const sideBySideWidth = 956.0;
  static const cardWidth = 340.0;
  static const gap = 56.0;

  final Profile profile;
  final List<CurrentlyItem> currently;
  final AppLocale locale;
  final DateTime now;
  final bool cvAvailable;

  static Uri cvUri(AppLocale locale) =>
      Uri.parse('/cv/lucas-schmidt-cv-${locale.name}.pdf');

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SectionShell(
      top: (width * 0.09).clamp(56.0, 120.0),
      bottom: (width * 0.07).clamp(48.0, 96.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = _Copy(
            profile: profile,
            locale: locale,
            cvAvailable: cvAvailable,
            displayWidth: width,
          );
          final card = CurrentlyCard(items: currently, now: now);
          if (constraints.maxWidth >= sideBySideWidth) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: copy),
                const SizedBox(width: gap),
                SizedBox(width: cardWidth, child: card),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: gap),
              card,
            ],
          );
        },
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({
    required this.profile,
    required this.locale,
    required this.cvAvailable,
    required this.displayWidth,
  });

  final Profile profile;
  final AppLocale locale;
  final bool cvAvailable;
  final double displayWidth;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: profile.role,
          excludeSemantics: true,
          child: Text(
            profile.role.toUpperCase(),
            style: LsType.eyebrow.copyWith(color: colors.accent),
          ),
        ),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          headingLevel: 1,
          label: profile.name,
          excludeSemantics: true,
          child: Text(
            profile.name.replaceFirst(' ', '\n'),
            style: LsType.displayFor(displayWidth).copyWith(color: colors.fg),
          ),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            profile.summary,
            style: LsType.lead.copyWith(color: colors.fg2),
          ),
        ),
        const SizedBox(height: 28 + LsSpacing.s2),
        Wrap(
          spacing: LsSpacing.s3,
          runSpacing: LsSpacing.s3,
          children: [
            if (cvAvailable)
              LsButton.primary(
                label: l10n.heroDownloadCv,
                icon: Icons.file_download_outlined,
                href: HeroSection.cvUri(locale),
                target: LinkTarget.blank,
              ),
            LsButton.ghost(
              label: l10n.heroEmailMe,
              icon: Icons.mail_outline,
              onPressed: () => SectionId.contact.scrollTo(context),
            ),
          ],
        ),
      ],
    );
  }
}
