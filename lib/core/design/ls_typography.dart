import 'package:flutter/painting.dart';

abstract final class LsFonts {
  static const sans = 'Inter Tight';
  static const mono = 'JetBrains Mono';
}

abstract final class LsType {
  static const display = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 128,
    height: 0.92,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.045 * 128,
  );
  static const displayPhone = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 56,
    height: 0.92,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.045 * 56,
  );
  static const h2 = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 48,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.03 * 48,
  );
  static const h2Phone = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.03 * 32,
  );
  static const h3 = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02 * 26,
  );
  static const body = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 16,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );
  static const bodySm = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const mono = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const monoLabel = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.06 * 12,
  );

  static TextStyle displayFor(double width) {
    final size = (width * 0.09).clamp(56.0, 128.0);
    return display.copyWith(fontSize: size, letterSpacing: -0.045 * size);
  }

  static const lead = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 19,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );
  static const button = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );
  static const brand = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.01 * 15,
  );
  static const eyebrow = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.08 * 12,
  );
  static const caption = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.08 * 11,
  );
  static const stat = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 44,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.03 * 44,
  );
  static const statSm = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.02 * 28,
  );

  static const statUnit = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 20,
    height: 1.1,
    fontWeight: FontWeight.w500,
  );
  static const statMono = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w400,
  );
  static const h3Feature = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.025 * 32,
  );
  static const tileBody = TextStyle(
    fontFamily: LsFonts.sans,
    fontSize: 15,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );
  static const tag = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const micro = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const monoSm = TextStyle(
    fontFamily: LsFonts.mono,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static TextStyle h2For(double width) {
    final size = (width * 0.04).clamp(32.0, 48.0);
    return h2.copyWith(fontSize: size, letterSpacing: -0.03 * size);
  }
}
