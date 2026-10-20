import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_interactive.dart';
import 'package:url_launcher/link.dart';

enum _LsButtonVariant { primary, inverse, ghost }

class LsButton extends StatelessWidget {
  const LsButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.href,
    this.target = LinkTarget.self,
  }) : _variant = _LsButtonVariant.primary,
       assert(onPressed == null || href == null, 'Pass onPressed or href.');

  const LsButton.inverse({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.href,
    this.target = LinkTarget.self,
  }) : _variant = _LsButtonVariant.inverse,
       assert(onPressed == null || href == null, 'Pass onPressed or href.');

  const LsButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.href,
    this.target = LinkTarget.self,
  }) : _variant = _LsButtonVariant.ghost,
       assert(onPressed == null || href == null, 'Pass onPressed or href.');

  static const iconSize = 16.0;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Uri? href;
  final LinkTarget target;
  final _LsButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final href = this.href;
    if (href == null) return _button(context, onPressed, isLink: false);
    return Link(
      uri: href,
      target: target,
      builder: (context, followLink) =>
          _button(context, followLink, isLink: true),
    );
  }

  Widget _button(
    BuildContext context,
    VoidCallback? onTap, {
    required bool isLink,
  }) {
    final colors = LsColors.of(context);
    final filled = _variant != _LsButtonVariant.ghost;
    final fill = _variant == _LsButtonVariant.primary
        ? colors.accent
        : colors.fg;
    final foreground = switch (_variant) {
      _LsButtonVariant.primary => colors.accentInk,
      _LsButtonVariant.inverse => colors.bg,
      _LsButtonVariant.ghost => colors.fg,
    };
    final horizontal = _variant == _LsButtonVariant.inverse ? 20.0 : 22.0;
    return MergeSemantics(
      child: Semantics(
        button: !isLink,
        link: isLink,
        enabled: onTap != null,
        child: LsInteractive(
          onPressed: onTap,
          builder: (context, hovered, focused) => LsFocusRing(
            visible: focused,
            child: Opacity(
              opacity: filled && hovered ? 0.88 : 1,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: LsSpacing.minTarget,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: LsSpacing.s3,
                ),
                decoration: BoxDecoration(
                  color: filled ? fill : null,
                  border: filled
                      ? null
                      : Border.all(color: hovered ? colors.fg2 : colors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: iconSize, color: foreground),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: LsType.button.copyWith(color: foreground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
