import 'package:flutter/widgets.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.accent = false});

  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = LsColors.of(context);
    return SizedBox(
      height: LsSpacing.hairline,
      width: double.infinity,
      child: ColoredBox(color: accent ? colors.accent : colors.line),
    );
  }
}
