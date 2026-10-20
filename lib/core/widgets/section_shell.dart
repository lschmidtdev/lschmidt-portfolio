import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_breakpoints.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_motion.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';

enum SectionId {
  work,
  experience,
  skills,
  contact;

  static final _keys = {
    for (final id in SectionId.values) id: GlobalKey(debugLabel: id.name),
  };

  GlobalKey get key => _keys[this]!;

  Future<void> scrollTo(BuildContext context) async {
    final target = key.currentContext;
    if (target == null) return;
    final motion = LsMotion.of(context);
    await Scrollable.ensureVisible(
      target,
      duration: motion.movement(LsMotion.reveal),
      curve: Curves.easeOut,
    );
  }
}

class SectionShell extends StatelessWidget {
  const SectionShell({
    super.key,
    required this.child,
    this.id,
    this.rule = false,
    this.top,
    this.bottom,
  });

  static const phonePadding = 64.0;
  static const desktopPadding = 96.0;

  final SectionId? id;
  final Widget child;
  final bool rule;
  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = LsBreakpoints.forWidth(width) == LsSize.phone
        ? phonePadding
        : desktopPadding;
    final gutter = LsSpacing.gutter(width);
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        top ?? padding,
        gutter,
        bottom ?? padding,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LsSpacing.contentMax),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
    final framed = rule
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: LsColors.of(context).line)),
            ),
            child: content,
          )
        : content;
    return KeyedSubtree(key: id?.key, child: framed);
  }
}
