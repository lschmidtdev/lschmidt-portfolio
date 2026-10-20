import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/domain/entities/currently_item.dart';
import 'package:lschmidt_portfolio/domain/usecases/filter_stale_currently.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';

class CurrentlyCard extends StatelessWidget {
  const CurrentlyCard({super.key, required this.items, required this.now});

  static const labelWidth = 88.0;

  final List<CurrentlyItem> items;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final l10n = AppLocalizations.of(context);
    final visible = filterStaleCurrently(items, now);
    return Semantics(
      container: true,
      label: l10n.currentlyTitle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: ExcludeSemantics(
                      child: Text(
                        l10n.currentlyTitle.toUpperCase(),
                        style: LsType.caption.copyWith(color: colors.fg3),
                      ),
                    ),
                  ),
                  const SizedBox(width: LsSpacing.s3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 7),
                      ),
                      const SizedBox(width: LsSpacing.s2),
                      Text(
                        l10n.currentlyAvailable.toUpperCase(),
                        style: LsType.caption.copyWith(
                          color: colors.accent,
                          letterSpacing: 0.06 * 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: Column(
                children: [
                  for (var i = 0; i < visible.length; i++)
                    _Row(item: visible[i], last: i == visible.length - 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.last});

  final CurrentlyItem item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return MergeSemantics(
      child: CustomPaint(
        painter: last ? null : _DashedBottomBorder(colors.line),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: CurrentlyCard.labelWidth,
                child: Text(
                  item.label,
                  style: LsType.mono.copyWith(color: colors.fg3),
                ),
              ),
              const SizedBox(width: LsSpacing.s3),
              Expanded(
                child: Text(
                  item.value,
                  style: LsType.mono.copyWith(color: colors.fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBottomBorder extends CustomPainter {
  _DashedBottomBorder(this.color);

  static const dash = 3.0;
  static const gap = 3.0;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height - 0.5),
        Offset((x + dash).clamp(0, size.width), size.height - 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedBottomBorder old) => old.color != color;
}
