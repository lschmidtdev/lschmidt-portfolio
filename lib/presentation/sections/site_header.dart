import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_motion.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/link_activation.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_interactive.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_link.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:lschmidt_portfolio/routes.dart';
import 'package:url_launcher/link.dart';

class SiteHeader extends StatelessWidget {
  const SiteHeader({
    super.key,
    required this.locale,
    required this.onLocaleSelected,
    required this.onToggleTheme,
  });

  static const headerPadding = 18.0;

  final AppLocale locale;
  final ValueChanged<AppLocale> onLocaleSelected;
  final VoidCallback onToggleTheme;

  void _scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;
    controller.animateTo(
      0,
      duration: LsMotion.of(context).movement(LsMotion.reveal),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = LsSpacing.gutter(width);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: gutter,
          vertical: headerPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LsSpacing.contentMax),
            child: SizedBox(
              width: double.infinity,
              child: Semantics(
                container: true,
                label: l10n.navMainLabel,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: LsSpacing.s4,
                  runSpacing: LsSpacing.s2,
                  children: [
                    _Brand(
                      href: pageUri(locale),
                      onActivated: () => _scrollToTop(context),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 28,
                      runSpacing: LsSpacing.s2,
                      children: [
                        for (final (id, label) in [
                          (SectionId.work, l10n.navWork),
                          (SectionId.experience, l10n.navExperience),
                          (SectionId.skills, l10n.navSkills),
                          (SectionId.contact, l10n.navContact),
                        ])
                          LsLink(
                            label: label,
                            href: pageUri(locale, section: id.name),
                            onActivated: () => id.scrollTo(context),
                          ),
                        _LanguageSwitch(
                          selected: locale,
                          onSelected: onLocaleSelected,
                        ),
                        _ThemeToggle(onPressed: onToggleTheme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.href, required this.onActivated});

  final Uri href;
  final VoidCallback onActivated;

  @override
  Widget build(BuildContext context) => Link(
    uri: href,
    builder: (context, followLink) =>
        _brand(context, withActivation(followLink, onActivated)),
  );

  Widget _brand(BuildContext context, VoidCallback? onPressed) {
    final colors = LsColors.of(context);
    return MergeSemantics(
      child: Semantics(
        link: true,
        linkUrl: href,
        child: LsInteractive(
          onPressed: onPressed,
          builder: (context, hovered, focused) => LsFocusRing(
            visible: focused,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: LsSpacing.minTarget),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.fg),
                    ),
                    child: Text(
                      'LS',
                      style: LsType.monoLabel.copyWith(
                        color: colors.fg,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.04 * 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: LsSpacing.s3),
                  Flexible(
                    child: Text(
                      SiteConfig.name,
                      style: LsType.brand.copyWith(
                        color: hovered ? colors.accent : colors.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.selected, required this.onSelected});

  final AppLocale selected;
  final ValueChanged<AppLocale> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    String labelFor(AppLocale locale) => switch (locale) {
      AppLocale.en => l10n.languageEnglishLabel,
      AppLocale.pt => l10n.languagePortugueseLabel,
    };
    return Semantics(
      container: true,
      label: l10n.languageGroupLabel,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(border: Border.all(color: colors.line)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final locale in AppLocale.values)
              _LanguageOption(
                code: locale.name.toUpperCase(),
                label: labelFor(locale),
                selected: locale == selected,
                onPressed: () => onSelected(locale),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: true,
        label: label,
        child: LsInteractive(
          onPressed: onPressed,
          builder: (context, hovered, focused) => LsFocusRing(
            visible: focused,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: LsSpacing.minTarget,
                minHeight: LsSpacing.minTarget,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: selected ? colors.fg : null,
              child: ExcludeSemantics(
                child: Text(
                  code,
                  style: LsType.monoLabel.copyWith(
                    color: selected
                        ? colors.bg
                        : hovered
                        ? colors.fg
                        : colors.fg2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: true,
        label: Theme.of(context).brightness == Brightness.light
            ? AppLocalizations.of(context).themeToggleToDark
            : AppLocalizations.of(context).themeToggleToLight,
        child: LsInteractive(
          onPressed: onPressed,
          builder: (context, hovered, focused) => LsFocusRing(
            visible: focused,
            child: Container(
              width: LsSpacing.minTarget,
              height: LsSpacing.minTarget,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: hovered ? colors.fg2 : colors.line),
              ),
              child: ExcludeSemantics(
                child: Icon(Icons.contrast, size: 16, color: colors.fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
