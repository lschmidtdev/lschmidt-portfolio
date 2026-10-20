import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_interactive.dart';
import 'package:url_launcher/link.dart';

enum _LsButtonVariant { primary, ghost }

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
    final primary = _variant == _LsButtonVariant.primary;
    final foreground = primary ? colors.accentInk : colors.fg;
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
              opacity: primary && hovered ? 0.88 : 1,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: LsSpacing.minTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: LsSpacing.s3,
                ),
                decoration: BoxDecoration(
                  color: primary ? colors.accent : null,
                  border: primary
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
