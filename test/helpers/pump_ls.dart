import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/design/ls_theme.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:lschmidt_portfolio/presentation/app_locale_x.dart';

extension PumpLs on WidgetTester {
  Future<void> pumpLs(
    Widget child, {
    double width = 1440,
    double height = 900,
    bool reducedMotion = false,
    bool light = false,
    AppLocale locale = AppLocale.en,
  }) async {
    view.devicePixelRatio = 1;
    view.physicalSize = Size(width, height);
    addTearDown(view.reset);
    binding.focusManager.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => binding.focusManager.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: light ? LsTheme.light() : LsTheme.dark(),
        locale: locale.flutterLocale,
        supportedLocales: [
          ...AppLocalizations.supportedLocales,
          AppLocale.pt.flutterLocale,
        ],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: app!,
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  Future<TestGesture> mouse() async {
    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    return gesture;
  }
}

Widget atWidth(
  double width,
  Widget child, {
  bool light = false,
  AppLocale locale = AppLocale.en,
}) {
  final theme = light ? LsTheme.light() : LsTheme.dark();
  return Theme(
    data: theme,
    child: Localizations(
      locale: locale.flutterLocale,
      delegates: AppLocalizations.localizationsDelegates,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(size: Size(width, 900), disableAnimations: true),
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
}
