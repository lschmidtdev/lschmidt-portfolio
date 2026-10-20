import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_motion.dart';

class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({super.key, required this.child});

  static const rise = 8.0;

  final Widget child;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LsMotion.reveal,
    value: 1,
  );
  ScrollPosition? _position;
  bool _revealed = false;
  bool _hidden = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideInitial());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = LsMotion.of(context).reduced;
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    if (_revealed) return;
    _position?.addListener(_check);
    if (_reduced && _hidden) _show();
  }

  bool _belowViewport() {
    final box = context.findRenderObject();
    final viewport = MediaQuery.maybeSizeOf(context)?.height;
    if (box is! RenderBox || !box.hasSize || viewport == null) return false;
    return box.localToGlobal(Offset.zero).dy >= viewport;
  }

  void _decideInitial() {
    if (!mounted || _revealed) return;
    if (_reduced || !_belowViewport()) {
      _revealed = true;
      _position?.removeListener(_check);
      return;
    }
    _hidden = true;
    _controller.value = 0;
  }

  void _check() {
    if (!mounted || _revealed || !_hidden) return;
    if (!_belowViewport()) _show();
  }

  void _show() {
    _revealed = true;
    _hidden = false;
    _position?.removeListener(_check);
    if (_reduced) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = Curves.easeOut.transform(_controller.value);
      return IgnorePointer(
        ignoring: t == 0,
        child: Opacity(
          opacity: t,
          alwaysIncludeSemantics: true,
          child: Transform.translate(
            offset: Offset(0, RevealOnScroll.rise * (1 - t)),
            child: child,
          ),
        ),
      );
    },
  );
}
