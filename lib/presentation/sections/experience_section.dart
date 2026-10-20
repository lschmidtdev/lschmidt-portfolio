import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/hairline.dart';
import 'package:lschmidt_portfolio/core/widgets/reveal_on_scroll.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/role.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';

class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key, required this.roles});

  static const headerGap = 32.0;
  static const periodWidth = 180.0;
  static const companyBasis = 260.0;
  static const summaryBasis = 360.0;
  static const columnGap = 32.0;
  static const rowGap = 8.0;
  static const rowPadding = 28.0;

  final List<Role> roles;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return SectionShell(
      id: SectionId.experience,
      top: (width * 0.09).clamp(64.0, 120.0),
      bottom: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RevealOnScroll(
            child: Padding(
              padding: const EdgeInsets.only(bottom: headerGap),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: LsSpacing.s4,
                runSpacing: LsSpacing.s4,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.experienceTitle,
                      style: LsType.h2For(width).copyWith(color: colors.fg),
                    ),
                  ),
                  Text(
                    l10n.experienceRange.toUpperCase(),
                    style: LsType.monoLabel.copyWith(color: colors.fg3),
                  ),
                ],
              ),
            ),
          ),
          const Hairline(accent: true),
          for (final role in roles) RevealOnScroll(child: _RoleRow(role: role)),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: ExperienceSection.rowPadding,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) =>
              _layout(context, constraints.maxWidth),
        ),
      ),
    );
  }

  Widget _layout(BuildContext context, double width) {
    final period = _Period(role: role);
    final company = _Company(role: role);
    final summary = _Summary(role: role);
    const columnGap = ExperienceSection.columnGap;
    const periodWidth = ExperienceSection.periodWidth;
    const companyBasis = ExperienceSection.companyBasis;
    const summaryBasis = ExperienceSection.summaryBasis;
    const single = periodWidth + companyBasis + summaryBasis + 2 * columnGap;
    const pair = periodWidth + companyBasis + columnGap;
    if (width >= single) {
      final free = width - single;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: periodWidth, child: period),
          const SizedBox(width: columnGap),
          SizedBox(width: companyBasis + free / 3, child: company),
          const SizedBox(width: columnGap),
          SizedBox(width: summaryBasis + free * 2 / 3, child: summary),
        ],
      );
    }
    if (width >= pair) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: periodWidth, child: period),
              const SizedBox(width: columnGap),
              Expanded(child: company),
            ],
          ),
          const SizedBox(height: ExperienceSection.rowGap),
          summary,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: periodWidth, child: period),
        ),
        const SizedBox(height: ExperienceSection.rowGap),
        company,
        const SizedBox(height: ExperienceSection.rowGap),
        summary,
      ],
    );
  }
}

class _Period extends StatelessWidget {
  const _Period({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: LsSpacing.s1),
      child: Text(
        role.period,
        style: LsType.mono.copyWith(
          color: role.current ? colors.accent : colors.fg3,
        ),
      ),
    );
  }
}

class _Company extends StatelessWidget {
  const _Company({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role.company,
          style: LsType.roleCompany.copyWith(color: colors.fg),
        ),
        const SizedBox(height: LsSpacing.s1),
        Text(role.title, style: LsType.bodySm.copyWith(color: colors.fg2)),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) => Text(
    role.summary,
    style: LsType.tileBody.copyWith(color: LsColors.of(context).fg2),
  );
}
