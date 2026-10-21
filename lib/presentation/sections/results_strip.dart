import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/reveal_on_scroll.dart';
import 'package:lschmidt_portfolio/core/widgets/section_shell.dart';
import 'package:lschmidt_portfolio/domain/entities/metric.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';

class ResultsStrip extends StatelessWidget {
  const ResultsStrip({super.key, required this.metrics});

  static const minCellWidth = 220.0;
  static const cellPadding = 24.0;
  static const cellVertical = 32.0;

  final List<Metric> metrics;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: colors.line)),
      ),
      child: SectionShell(
        top: 0,
        bottom: 0,
        child: Semantics(
          container: true,
          label: AppLocalizations.of(context).resultsLabel,
          child: RevealOnScroll(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / minCellWidth)
                    .floor()
                    .clamp(1, metrics.length);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var start = 0;
                      start < metrics.length;
                      start += columns
                    )
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = start; i < start + columns; i++)
                              Expanded(
                                child: i < metrics.length
                                    ? _Cell(
                                        metric: metrics[i],
                                        first: i == 0,
                                        last: i == metrics.length - 1,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.metric, required this.first, required this.last});

  final Metric metric;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final unit = metric.unit;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last ? null : Border(right: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          first ? 0 : ResultsStrip.cellPadding,
          ResultsStrip.cellVertical,
          last ? 0 : ResultsStrip.cellPadding,
          ResultsStrip.cellVertical,
        ),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: metric.value,
                  style: LsType.stat.copyWith(color: colors.accent),
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: LsType.statUnit.copyWith(color: colors.fg3),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                metric.label,
                style: LsType.bodySm.copyWith(color: colors.fg2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
