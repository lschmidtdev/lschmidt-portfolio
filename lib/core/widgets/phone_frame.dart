import 'package:flutter/widgets.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';

class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.radius = 28,
    this.padding = 8,
    this.strong = true,
  });

  final double width;
  final double height;
  final double radius;
  final double padding;
  final bool strong;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: strong ? colors.fg3 : colors.line,
          width: LsSpacing.hairline,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - padding),
        child: child,
      ),
    );
  }
}
