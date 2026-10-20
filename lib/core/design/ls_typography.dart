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
}
