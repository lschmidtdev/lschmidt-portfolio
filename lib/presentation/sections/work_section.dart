import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/reveal_on_scroll.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/project.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:lschmidt_portfolio/presentation/sections/project_tile.dart';

class WorkSection extends StatelessWidget {
  const WorkSection({super.key, required this.projects});

  static const featureBasis = 640.0;
  static const tileBasis = 340.0;
  static const gap = 16.0;
  static const headerGap = 40.0;

  final List<Project> projects;

  static double _basis(Project project) =>
      project.featured ? featureBasis : tileBasis;

  static double _grow(Project project) => project.featured ? 2 : 1;

  static List<List<Project>> lines(List<Project> projects, double width) {
    final result = <List<Project>>[];
    var used = 0.0;
    for (final project in projects) {
      final next = result.isEmpty ? 0.0 : used + gap;
      if (result.isNotEmpty && next + _basis(project) <= width) {
        result.last.add(project);
        used = next + _basis(project);
      } else {
        result.add([project]);
        used = _basis(project);
      }
    }
    return result;
  }

  static List<double> widths(List<Project> line, double width) {
    final used =
        line.fold(0.0, (sum, project) => sum + _basis(project)) +
        gap * (line.length - 1);
    if (line.length == 1) return [width];
    final free = width - used;
    final grow = line.fold(0.0, (sum, project) => sum + _grow(project));
    return [
      for (final project in line)
        _basis(project) + free * _grow(project) / grow,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final count = projects.length.toString().padLeft(2, '0');
    return SectionShell(
      id: SectionId.work,
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
                spacing: gap,
                runSpacing: gap,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.workTitle,
                      style: LsType.h2For(width).copyWith(color: colors.fg),
                    ),
                  ),
                  Text(
                    l10n.workCount(count).toUpperCase(),
                    style: LsType.monoLabel.copyWith(color: colors.fg3),
                  ),
                ],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth;
              final rows = lines(projects, available);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: gap),
                    _Line(
                      projects: rows[i],
                      widths: widths(rows[i], available),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.projects, required this.widths});

  final List<Project> projects;
  final List<double> widths;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < projects.length; i++) ...[
          if (i > 0) const SizedBox(width: WorkSection.gap),
          SizedBox(
            width: widths[i],
            child: RevealOnScroll(
              child: ProjectTile(project: projects[i], width: widths[i]),
            ),
          ),
        ],
      ],
    ),
  );
}
