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

  static final _fallback = SectionKeys();

  GlobalKey get key => _fallback[this];

  GlobalKey keyIn(BuildContext context) =>
      (SectionScope.maybeOf(context) ?? _fallback)[this];

  FocusNode focusIn(BuildContext context) =>
      (SectionScope.maybeOf(context) ?? _fallback).focusOf(this);

  FocusNode fieldIn(BuildContext context) =>
      (SectionScope.maybeOf(context) ?? _fallback).fieldOf(this);

  Future<void> scrollTo(BuildContext context) async {
    final target = keyIn(context).currentContext;
    if (target == null) return;
    final heading = focusIn(context);
    final field = fieldIn(context);
    final motion = LsMotion.of(context);
    await Scrollable.ensureVisible(
      target,
      duration: motion.movement(LsMotion.reveal),
      curve: Curves.easeOut,
    );
    final keyboard =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final focus = keyboard && field.context != null ? field : heading;
    if (focus.context != null) focus.requestFocus();
  }
}

class SectionKeys {
  final _keys = {
    for (final id in SectionId.values) id: GlobalKey(debugLabel: id.name),
  };
  final _focus = {
    for (final id in SectionId.values)
      id: FocusNode(debugLabel: id.name, skipTraversal: true),
  };
  final _fields = {
    for (final id in SectionId.values)
      id: FocusNode(debugLabel: '${id.name} field'),
  };

  GlobalKey operator [](SectionId id) => _keys[id]!;

  FocusNode focusOf(SectionId id) => _focus[id]!;

  FocusNode fieldOf(SectionId id) => _fields[id]!;

  void dispose() {
    for (final node in [..._focus.values, ..._fields.values]) {
      node.dispose();
    }
  }
}

class SectionFocus extends StatelessWidget {
  const SectionFocus({super.key, required this.id, required this.child});

  final SectionId id;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: id.focusIn(context), child: child);
}

class SectionScope extends InheritedWidget {
  const SectionScope({super.key, required this.keys, required super.child});

  final SectionKeys keys;

  static SectionKeys? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SectionScope>()?.keys;

  @override
  bool updateShouldNotify(SectionScope oldWidget) => keys != oldWidget.keys;
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
    return KeyedSubtree(key: id?.keyIn(context), child: framed);
  }
}
