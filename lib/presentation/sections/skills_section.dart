import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/hairline.dart';
import 'package:lschmidt_portfolio/core/widgets/reveal_on_scroll.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/education.dart';
import 'package:lschmidt_portfolio/domain/entities/skill_group.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';

class SkillsSection extends StatelessWidget {
  const SkillsSection({
    super.key,
    required this.groups,
    required this.education,
    required this.languages,
  });

  static const headerGap = 32.0;
  static const minCellWidth = 260.0;
  static const cellPadding = 24.0;
  static const labelGap = 16.0;
  static const noteSpacing = 48.0;
  static const nonBreakingGap = '  ';
  static const separator = ' · ';

  final List<SkillGroup> groups;
  final List<Education> education;
  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final educationText = education
        .map((e) => '${e.degree}, ${e.institution} — ${e.period}')
        .join(separator);
    return SectionShell(
      id: SectionId.skills,
      top: (width * 0.09).clamp(64.0, 120.0),
      bottom: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RevealOnScroll(
            child: Padding(
              padding: const EdgeInsets.only(bottom: headerGap),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SectionFocus(
                  id: SectionId.skills,
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.skillsTitle,
                      style: LsType.h2For(width).copyWith(color: colors.fg),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Hairline(accent: true),
          RevealOnScroll(child: _Grid(groups: groups)),
          RevealOnScroll(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: cellPadding),
              child: Wrap(
                spacing: noteSpacing,
                runSpacing: LsSpacing.s2,
                children: [
                  _Note(label: l10n.skillsEducation, text: educationText),
                  _Note(
                    label: l10n.skillsLanguages,
                    text: languages.join(separator),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.groups});

  final List<SkillGroup> groups;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / SkillsSection.minCellWidth)
          .floor()
          .clamp(1, groups.length);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < groups.length; start += columns)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++)
                    Expanded(
                      child: start + column < groups.length
                          ? _Cell(
                              group: groups[start + column],
                              first: column == 0,
                              last: column == columns - 1,
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.group, required this.first, required this.last});

  final SkillGroup group;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          first ? 0 : SkillsSection.cellPadding,
          SkillsSection.cellPadding,
          last ? 0 : SkillsSection.cellPadding,
          SkillsSection.cellPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title,
              style: LsType.caption.copyWith(
                color: group.primary ? colors.accent : colors.fg3,
              ),
            ),
            const SizedBox(height: SkillsSection.labelGap),
            Text(
              group.items.join(SkillsSection.separator),
              style: LsType.skillItems.copyWith(
                color: group.primary ? colors.fg : colors.fg2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label.toUpperCase() + SkillsSection.nonBreakingGap,
            style: LsType.caption.copyWith(color: colors.fg3),
          ),
          TextSpan(text: text),
        ],
      ),
      style: LsType.bodySm.copyWith(color: colors.fg2),
    );
  }
}
