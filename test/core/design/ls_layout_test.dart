import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_breakpoints.dart';
import 'package:lschmidt_portfolio/core/design/ls_motion.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';

void main() {
  group('LsBreakpoints', () {
    test('values', () {
      expect(LsBreakpoints.phone, 600);
      expect(LsBreakpoints.tablet, 1024);
    });

    test('forWidth classifies around the edges', () {
      expect(LsBreakpoints.forWidth(599), LsSize.phone);
      expect(LsBreakpoints.forWidth(600), LsSize.tablet);
      expect(LsBreakpoints.forWidth(1023), LsSize.tablet);
      expect(LsBreakpoints.forWidth(1024), LsSize.desktop);
    });
  });

  group('LsSpacing.gutter', () {
    test('is 16 on narrow screens', () {
      expect(LsSpacing.gutter(360), 16);
      expect(LsSpacing.gutter(400), 16);
    });

    test('is 4 percent of the width in between', () {
      expect(LsSpacing.gutter(800), closeTo(32, 0.001));
    });

    test('is capped at 48', () {
      expect(LsSpacing.gutter(1440), 48);
      expect(LsSpacing.gutter(3000), 48);
    });
  });

  group('LsType', () {
    test('families', () {
      expect(LsType.display.fontFamily, LsFonts.sans);
      expect(LsType.body.fontFamily, LsFonts.sans);
      expect(LsType.mono.fontFamily, LsFonts.mono);
      expect(LsType.monoLabel.fontFamily, LsFonts.mono);
    });

    test('display is the largest style', () {
      for (final style in [
        LsType.h2,
        LsType.h3,
        LsType.body,
        LsType.bodySm,
        LsType.mono,
        LsType.monoLabel,
      ]) {
        expect(LsType.display.fontSize!, greaterThan(style.fontSize!));
      }
    });
  });

  group('LsMotion', () {
    testWidgets('reads the platform reduce-motion flag', (tester) async {
      late LsMotion motion;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              motion = LsMotion.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(motion.reduced, isTrue);
      expect(motion.movement(LsMotion.reveal), Duration.zero);
    });

    test('keeps durations when motion is allowed', () {
      const motion = LsMotion(reduced: false);
      expect(motion.movement(LsMotion.reveal), LsMotion.reveal);
      expect(motion.movement(LsMotion.themeFade), LsMotion.themeFade);
    });
  });
}
