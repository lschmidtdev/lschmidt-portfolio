@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_colors.dart';
import 'package:lschmidt_portfolio/core/design/ls_typography.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/sections/hero.dart';
import 'package:lschmidt_portfolio/presentation/sections/site_header.dart';

import '../helpers/fake_portfolio_repository.dart';
import '../helpers/pump_ls.dart';

const _fontFiles = {
  LsFonts.sans: [
    'InterTight-Regular.ttf',
    'InterTight-Medium.ttf',
    'InterTight-SemiBold.ttf',
  ],
  LsFonts.mono: ['JetBrainsMono-Regular.ttf', 'JetBrainsMono-Medium.ttf'],
};

Future<void> _loadBundledFonts() async {
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  for (final family in _fontFiles.entries) {
    final loader = FontLoader(family.key);
    for (final file in family.value) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

final _canvasKey = GlobalKey();
final _contentKey = GlobalKey();

Future<void> _writePng(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary =
        _canvasKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Widget _canvas(Size size, Widget child) => Align(
  alignment: Alignment.topLeft,
  child: RepaintBoundary(
    key: _canvasKey,
    child: SizedBox.fromSize(size: size, child: child),
  ),
);

Widget _mark(double canvas, double markFraction) {
  final side = canvas * markFraction;
  final colors = LsColors.dark;
  return ColoredBox(
    color: colors.bg,
    child: Center(
      child: Container(
        width: side,
        height: side,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: colors.fg, width: side / 18),
        ),
        child: Text(
          'LS',
          style: TextStyle(
            fontFamily: LsFonts.mono,
            fontWeight: FontWeight.w500,
            fontSize: side * 0.42,
            letterSpacing: side * 0.42 * 0.04,
            color: colors.fg,
            height: 1,
          ),
        ),
      ),
    ),
  );
}

const _icons = {
  'web/favicon.png': (64.0, 0.78),
  'web/icons/Icon-192.png': (192.0, 0.62),
  'web/icons/Icon-512.png': (512.0, 0.62),
  'web/icons/Icon-maskable-192.png': (192.0, 0.5),
  'web/icons/Icon-maskable-512.png': (512.0, 0.5),
};

void main() {
  setUpAll(_loadBundledFonts);

  testWidgets('renders the link preview image', (tester) async {
    final content = FakePortfolioRepository.contentFor(AppLocale.en);
    const layoutWidth = 1600.0;
    await tester.pumpLs(
      _canvas(
        const Size(1200, 630),
        ColoredBox(
          color: LsColors.dark.bg,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: layoutWidth,
              maxWidth: layoutWidth,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Transform.scale(
                scale: 1200 / layoutWidth,
                alignment: Alignment.topLeft,
                child: Column(
                  key: _contentKey,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SiteHeader(
                      locale: AppLocale.en,
                      onLocaleSelected: (_) {},
                      onToggleTheme: () {},
                    ),
                    HeroSection(
                      profile: content.profile,
                      currently: content.currently,
                      locale: AppLocale.en,
                      now: DateTime(2026, 10, 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      width: layoutWidth,
      height: 900,
      reducedMotion: true,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(_contentKey)).height * 1200 / layoutWidth,
      lessThanOrEqualTo(630),
    );
    await _writePng(tester, 'web/og-image.png');
  });

  for (final icon in _icons.entries) {
    testWidgets('renders ${icon.key}', (tester) async {
      final (size, fraction) = icon.value;
      await tester.pumpLs(
        _canvas(Size(size, size), _mark(size, fraction)),
        width: size,
        height: size,
        reducedMotion: true,
      );
      await tester.pumpAndSettle();
      await _writePng(tester, icon.key);
    });
  }
}
