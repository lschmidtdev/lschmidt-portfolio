import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/config/site_config.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, this.cvAvailable = SiteConfig.cvAvailable});

  static const verticalPadding = 24.0;
  static const gap = 12.0;

  final bool cvAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final gutter = LsSpacing.gutter(MediaQuery.sizeOf(context).width);
    final style = LsType.monoSm.copyWith(color: colors.fg3);
    final built = cvAvailable
        ? '${l10n.footerBuilt} · ${l10n.footerCvUpdated(SiteConfig.cvUpdated)}'
        : l10n.footerBuilt;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LsSpacing.contentMax),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: gutter,
              vertical: verticalPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: gap,
                runSpacing: gap,
                children: [
                  Text(l10n.footerCopyright(SiteConfig.name), style: style),
                  Text(built, style: style),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
