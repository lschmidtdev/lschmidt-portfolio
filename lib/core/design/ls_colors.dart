import 'package:flutter/material.dart';

@immutable
class LsColors extends ThemeExtension<LsColors> {
  const LsColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.accent,
    required this.accentInk,
  });

  static const dark = LsColors(
    bg: Color(0xFF0B0C0E),
    surface: Color(0xFF111316),
    surface2: Color(0xFF16191D),
    line: Color(0xFF24282E),
    fg: Color(0xFFE9EAEC),
    fg2: Color(0xFFA3A8AF),
    fg3: Color(0xFF868C94),
    accent: Color(0xFF6FB1E8),
    accentInk: Color(0xFF0B0C0E),
  );

  static const light = LsColors(
    bg: Color(0xFFF4F4F2),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECECE9),
    line: Color(0xFFD9DAD6),
    fg: Color(0xFF0E0F11),
    fg2: Color(0xFF4A4F56),
    fg3: Color(0xFF5F646B),
    accent: Color(0xFF1F6BA8),
    accentInk: Color(0xFFFFFFFF),
  );

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color fg;
  final Color fg2;
  final Color fg3;
  final Color accent;
  final Color accentInk;

  static LsColors of(BuildContext context) =>
      Theme.of(context).extension<LsColors>()!;

  @override
  LsColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? fg,
    Color? fg2,
    Color? fg3,
    Color? accent,
    Color? accentInk,
  }) => LsColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    line: line ?? this.line,
    fg: fg ?? this.fg,
    fg2: fg2 ?? this.fg2,
    fg3: fg3 ?? this.fg3,
    accent: accent ?? this.accent,
    accentInk: accentInk ?? this.accentInk,
  );

  @override
  LsColors lerp(ThemeExtension<LsColors>? other, double t) {
    if (other is! LsColors) return this;
    return LsColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      line: Color.lerp(line, other.line, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LsColors &&
      other.bg == bg &&
      other.surface == surface &&
      other.surface2 == surface2 &&
      other.line == line &&
      other.fg == fg &&
      other.fg2 == fg2 &&
      other.fg3 == fg3 &&
      other.accent == accent &&
      other.accentInk == accentInk;

  @override
  int get hashCode =>
      Object.hash(bg, surface, surface2, line, fg, fg2, fg3, accent, accentInk);
}
