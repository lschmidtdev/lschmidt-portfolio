import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/core/widgets/link_activation.dart';
import 'package:lschmidt_portfolio/core/widgets/ls_interactive.dart';
import 'package:url_launcher/link.dart';

class LsLink extends StatelessWidget {
  const LsLink({
    super.key,
    required this.label,
    this.onPressed,
    this.href,
    this.target = LinkTarget.self,
    this.onActivated,
    this.style = LsType.monoLabel,
    this.uppercase = true,
  }) : assert(onPressed == null || href == null, 'Pass onPressed or href.');

  final String label;
  final VoidCallback? onPressed;
  final Uri? href;
  final LinkTarget target;
  final VoidCallback? onActivated;
  final TextStyle style;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final href = this.href;
    if (href == null) return _link(context, onPressed);
    return Link(
      uri: href,
      target: target,
      builder: (context, followLink) =>
          _link(context, withActivation(followLink, onActivated)),
    );
  }

  Widget _link(BuildContext context, VoidCallback? onTap) {
    final colors = LsColors.of(context);
    return MergeSemantics(
      child: Semantics(
        link: true,
        label: label,
        enabled: onTap != null,
        child: LsInteractive(
          onPressed: onTap,
          builder: (context, hovered, focused) => LsFocusRing(
            visible: focused,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: LsSpacing.minTarget,
                minWidth: LsSpacing.minTarget,
              ),
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    uppercase ? label.toUpperCase() : label,
                    style: style.copyWith(
                      color: hovered ? colors.fg : colors.fg2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
