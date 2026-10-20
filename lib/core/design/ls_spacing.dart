abstract final class LsSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s12 = 48.0;
  static const s16 = 64.0;
  static const s24 = 96.0;

  static const contentMax = 1200.0;
  static const minTarget = 48.0;
  static const hairline = 1.0;

  static double gutter(double width) => (width * 0.04).clamp(16.0, 48.0);
}
