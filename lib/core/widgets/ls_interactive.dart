import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';

class LsInteractive extends StatefulWidget {
  const LsInteractive({
    super.key,
    required this.onPressed,
    required this.builder,
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, bool hovered, bool focused)
  builder;
  final FocusNode? focusNode;

  @override
  State<LsInteractive> createState() => _LsInteractiveState();
}

class _LsInteractiveState extends State<LsInteractive> {
  bool _hovered = false;
  bool _focused = false;

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  Object? _press(Intent _) {
    widget.onPressed?.call();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _press),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: _press,
        ),
      },
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: SelectionContainer.disabled(
            child: widget.builder(
              context,
              _hovered && enabled,
              _focused && enabled,
            ),
          ),
        ),
      ),
    );
  }
}

class LsFocusRing extends StatelessWidget {
  const LsFocusRing({super.key, required this.visible, required this.child});

  static const gap = 2.0;
  static const width = 2.0;

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return CustomPaint(
      foregroundPainter: _FocusRingPainter(
        visible: visible,
        gapColor: colors.bg,
        ringColor: colors.accent,
      ),
      child: child,
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.visible,
    required this.gapColor,
    required this.ringColor,
  });

  final bool visible;
  final Color gapColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect.inflate(LsFocusRing.gap / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = LsFocusRing.gap
        ..color = gapColor,
    );
    canvas.drawRect(
      rect.inflate(LsFocusRing.gap + LsFocusRing.width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = LsFocusRing.width
        ..color = ringColor,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.visible != visible ||
      old.gapColor != gapColor ||
      old.ringColor != ringColor;
}
