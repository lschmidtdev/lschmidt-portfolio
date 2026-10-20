import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_theme.dart';

double _channel(double value) => value <= 0.03928
    ? value / 12.92
    : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _channel(color.r) +
    0.7152 * _channel(color.g) +
    0.0722 * _channel(color.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('LsColors.dark', () {
    test('matches the spec tokens', () {
      expect(LsColors.dark.bg, const Color(0xFF0B0C0E));
      expect(LsColors.dark.surface, const Color(0xFF111316));
      expect(LsColors.dark.surface2, const Color(0xFF16191D));
      expect(LsColors.dark.line, const Color(0xFF24282E));
      expect(LsColors.dark.fg, const Color(0xFFE9EAEC));
      expect(LsColors.dark.fg2, const Color(0xFFA3A8AF));
      expect(LsColors.dark.fg3, const Color(0xFF868C94));
      expect(LsColors.dark.accent, const Color(0xFF6FB1E8));
      expect(LsColors.dark.accentInk, const Color(0xFF0B0C0E));
    });
  });

  group('LsColors.light', () {
    test('matches the spec tokens', () {
      expect(LsColors.light.bg, const Color(0xFFF4F4F2));
      expect(LsColors.light.surface, const Color(0xFFFFFFFF));
      expect(LsColors.light.surface2, const Color(0xFFECECE9));
      expect(LsColors.light.line, const Color(0xFFD9DAD6));
      expect(LsColors.light.fg, const Color(0xFF0E0F11));
      expect(LsColors.light.fg2, const Color(0xFF4A4F56));
      expect(LsColors.light.fg3, const Color(0xFF5F646B));
      expect(LsColors.light.accent, const Color(0xFF1F6BA8));
      expect(LsColors.light.accentInk, const Color(0xFFFFFFFF));
    });
  });

  for (final entry in {
    'dark': LsColors.dark,
    'light': LsColors.light,
  }.entries) {
    group('${entry.key} contrast', () {
      final colors = entry.value;

      test('fg2 on bg is at least 4.5:1', () {
        expect(_contrast(colors.fg2, colors.bg), greaterThanOrEqualTo(4.5));
      });

      test('fg3 on bg is at least 4.5:1', () {
        expect(_contrast(colors.fg3, colors.bg), greaterThanOrEqualTo(4.5));
      });

      test('accent on bg is at least 4.5:1', () {
        expect(_contrast(colors.accent, colors.bg), greaterThanOrEqualTo(4.5));
      });

      test('accentInk on accent is at least 4.5:1', () {
        expect(
          _contrast(colors.accentInk, colors.accent),
          greaterThanOrEqualTo(4.5),
        );
      });
    });
  }

  group('LsColors ThemeExtension', () {
    test('lerp at the ends returns the endpoints', () {
      expect(LsColors.dark.lerp(LsColors.light, 0), LsColors.dark);
      expect(LsColors.dark.lerp(LsColors.light, 1), LsColors.light);
    });

    test('lerp ignores a foreign extension', () {
      expect(LsColors.dark.lerp(null, 0.5), LsColors.dark);
    });

    test('copyWith replaces only the given field', () {
      final copy = LsColors.dark.copyWith(accent: const Color(0xFF000000));
      expect(copy.accent, const Color(0xFF000000));
      expect(copy.bg, LsColors.dark.bg);
    });
  });

  group('LsTheme', () {
    test('dark exposes LsColors.dark', () {
      expect(LsTheme.dark().extension<LsColors>(), LsColors.dark);
    });

    test('light exposes LsColors.light', () {
      expect(LsTheme.light().extension<LsColors>(), LsColors.light);
    });

    test('scaffold background follows bg', () {
      expect(LsTheme.dark().scaffoldBackgroundColor, LsColors.dark.bg);
      expect(LsTheme.light().scaffoldBackgroundColor, LsColors.light.bg);
    });
  });
}
