import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/painting.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_spacing.dart';
import 'package:lschmidt_portfolio/core/design/ls_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final platformGoldens = Platform.environment.containsKey('PLATFORM_GOLDENS');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: LsTheme.dark(),
      goldenTestTheme: GoldenTestTheme(
        backgroundColor: LsColors.dark.surface,
        borderColor: LsColors.dark.line,
        nameTextStyle: TextStyle(
          fontFamily: 'Ahem',
          fontSize: 12,
          color: LsColors.dark.fg2,
        ),
        padding: const EdgeInsets.all(LsSpacing.s4),
      ),
      ciGoldensConfig: CiGoldensConfig(
        diffThreshold: Platform.isLinux ? 0 : 0.01,
      ),
      platformGoldensConfig: PlatformGoldensConfig(enabled: platformGoldens),
    ),
    run: testMain,
  );
}
