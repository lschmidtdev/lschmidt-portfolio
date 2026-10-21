import 'package:flutter/material.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';

abstract final class LsTheme {
  static ThemeData dark() => _build(Brightness.dark, LsColors.dark);

  static ThemeData light() => _build(Brightness.light, LsColors.light);

  static ThemeData _build(Brightness brightness, LsColors colors) {
    final scheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            surface: colors.bg,
            primary: colors.accent,
            onPrimary: colors.accentInk,
            outline: colors.line,
            onSurface: colors.fg,
          )
        : ColorScheme.light(
            surface: colors.bg,
            primary: colors.accent,
            onPrimary: colors.accentInk,
            outline: colors.line,
            onSurface: colors.fg,
          );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      dividerColor: colors.line,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      fontFamily: LsFonts.sans,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colors.accent.withValues(alpha: 0.3),
        cursorColor: colors.accent,
      ),
      textTheme: const TextTheme(
        displayLarge: LsType.display,
        headlineMedium: LsType.h2,
        titleLarge: LsType.h3,
        bodyLarge: LsType.body,
        bodyMedium: LsType.body,
        bodySmall: LsType.bodySm,
        labelLarge: LsType.mono,
        labelSmall: LsType.monoLabel,
      ).apply(displayColor: colors.fg, bodyColor: colors.fg2),
      extensions: [colors],
    );
  }
}
