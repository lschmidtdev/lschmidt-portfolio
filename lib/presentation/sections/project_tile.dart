import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_button.dart';
import 'package:lschmidt_portfolio/core/widgets/phone_frame.dart';
import 'package:lschmidt_portfolio/domain/entities/metric.dart';
import 'package:lschmidt_portfolio/domain/entities/project.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:url_launcher/link.dart';

class ProjectTile extends StatefulWidget {
  const ProjectTile({super.key, required this.project, required this.width});

  static const frameKey = Key('project-tile-frame');
  static const padding = 32.0;
  static const gap = 18.0;
  static const splitWidth = 600.0;
  static const phonePanelMinHeight = 420.0;

  final Project project;
  final double width;

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final project = widget.project;
    final split =
        widget.width - 2 * LsSpacing.hairline >= ProjectTile.splitWidth;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: DecoratedBox(
        key: ProjectTile.frameKey,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: _hovered ? colors.fg3 : colors.line),
        ),
        child: project.featured
            ? _FeatureBody(project: project, split: split)
            : _Copy(project: project, feature: false, fill: true),
      ),
    );
  }
}

class _FeatureBody extends StatelessWidget {
  const _FeatureBody({required this.project, required this.split});

  final Project project;
  final bool split;

  @override
  Widget build(BuildContext context) {
    if (!split) {
      return ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Copy(project: project, feature: true, fill: false),
            const _PhonePanel(split: false),
          ],
        ),
      );
    }
    return ClipRect(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Copy(project: project, feature: true, fill: true)),
            const Expanded(child: _PhonePanel(split: true)),
          ],
        ),
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({
    required this.project,
    required this.feature,
    required this.fill,
  });

  final Project project;
  final bool feature;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final tail = _tail(context);
    return Padding(
      padding: const EdgeInsets.all(ProjectTile.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${project.index} — ${project.eyebrow}',
            style: LsType.monoLabel.copyWith(color: colors.fg3),
          ),
          const SizedBox(height: ProjectTile.gap),
          Semantics(
            header: true,
            child: Text(
              project.title,
              style: (feature ? LsType.h3Feature : LsType.h3).copyWith(
                color: colors.fg,
              ),
            ),
          ),
          const SizedBox(height: ProjectTile.gap),
          Text(
            project.summary,
            style: (feature ? LsType.body : LsType.tileBody).copyWith(
              color: colors.fg2,
            ),
          ),
          if (project.tags.isNotEmpty) ...[
            const SizedBox(height: ProjectTile.gap),
            _Tags(tags: project.tags),
          ],
          if (tail != null) ...[
            const SizedBox(height: ProjectTile.gap),
            if (fill)
              Expanded(
                child: Align(alignment: Alignment.bottomCenter, child: tail),
              )
            else
              tail,
          ],
        ],
      ),
    );
  }

  Widget? _tail(BuildContext context) {
    final colors = LsColors.of(context);
    final footnote = project.footnote;
    final playStoreUrl = project.playStoreUrl;
    final parts = <Widget>[
      if (project.stats.isNotEmpty)
        _Stats(stats: project.stats, headline: project.headlineStats),
      if (footnote != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: LsSpacing.s4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.line)),
          ),
          child: Text(
            footnote,
            style: LsType.monoSm.copyWith(color: colors.fg2),
          ),
        ),
      if (playStoreUrl != null)
        Align(
          alignment: Alignment.centerLeft,
          child: LsButton.inverse(
            label: AppLocalizations.of(context).workPlayStore,
            icon: Icons.play_arrow_outlined,
            href: playStoreUrl,
            target: LinkTarget.blank,
          ),
        ),
    ];
    if (parts.isEmpty) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(height: ProjectTile.gap),
          parts[i],
        ],
      ],
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(border: Border.all(color: colors.line)),
            child: Text(tag, style: LsType.tag.copyWith(color: colors.fg2)),
          ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats, required this.headline});

  final List<Metric> stats;
  final bool headline;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final inset = headline ? 16.0 : 12.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < stats.length; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == stats.length - 1
                        ? null
                        : Border(right: BorderSide(color: colors.line)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      i == 0 ? 0 : inset,
                      LsSpacing.s4,
                      i == stats.length - 1 ? 0 : inset,
                      0,
                    ),
                    child: _Stat(stat: stats[i], headline: headline),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.stat, required this.headline});

  final Metric stat;
  final bool headline;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final unit = stat.unit;
    final value = unit == null ? stat.value : '${stat.value} $unit';
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: headline
                ? LsType.statSm.copyWith(color: colors.accent)
                : LsType.statMono.copyWith(color: colors.fg),
          ),
          const SizedBox(height: LsSpacing.s1),
          Text(
            stat.label,
            style: (headline ? LsType.tag : LsType.micro).copyWith(
              color: colors.fg3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhonePanel extends StatelessWidget {
  const _PhonePanel({required this.split});

  final bool split;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    final side = BorderSide(color: colors.line);
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: ProjectTile.phonePanelMinHeight,
        ),
        padding: const EdgeInsets.all(ProjectTile.padding),
        decoration: BoxDecoration(
          color: colors.surface2,
          border: split ? Border(left: side) : Border(top: side),
        ),
        child: const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PhoneFrame(width: 180, height: 370, child: _ReceiptScreen()),
                SizedBox(width: LsSpacing.s4),
                PhoneFrame(
                  width: 160,
                  height: 330,
                  radius: 26,
                  padding: 7,
                  strong: false,
                  child: _BalancesScreen(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.factor});

  final double height;
  final double factor;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: factor,
      child: SizedBox(
        height: height,
        child: ColoredBox(color: LsColors.of(context).line),
      ),
    ),
  );
}

class _ReceiptScreen extends StatelessWidget {
  const _ReceiptScreen();

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Bar(height: 8, factor: 0.6),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: CustomPaint(painter: _DashedBox(colors.fg3)),
            ),
            const SizedBox(height: 10),
            const _Bar(height: 6, factor: 0.9),
            const SizedBox(height: 10),
            const _Bar(height: 6, factor: 0.75),
            const SizedBox(height: 10),
            const _Bar(height: 6, factor: 0.82),
            const Spacer(),
            SizedBox(height: 32, child: ColoredBox(color: colors.accent)),
          ],
        ),
      ),
    );
  }
}

class _BalancesScreen extends StatelessWidget {
  const _BalancesScreen();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: LsColors.of(context).surface,
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Bar(height: 8, factor: 0.5),
          SizedBox(height: 18),
          _Bar(height: 6, factor: 0.85),
          SizedBox(height: 10),
          _Bar(height: 6, factor: 0.7),
          SizedBox(height: 10),
          _Bar(height: 6, factor: 0.78),
          SizedBox(height: 10),
          _Bar(height: 6, factor: 0.6),
        ],
      ),
    ),
  );
}

class _DashedBox extends CustomPainter {
  _DashedBox(this.color);

  static const dash = 4.0;
  static const gap = 3.0;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, 0.5), Offset(end, 0.5), paint);
      canvas.drawLine(
        Offset(x, size.height - 0.5),
        Offset(end, size.height - 0.5),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += dash + gap) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(0.5, y), Offset(0.5, end), paint);
      canvas.drawLine(
        Offset(size.width - 0.5, y),
        Offset(size.width - 0.5, end),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color;
}
