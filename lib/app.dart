import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lschmidt_portfolio/core/design/ls_motion.dart';
import 'package:lschmidt_portfolio/core/design/ls_theme.dart';
import 'package:lschmidt_portfolio/core/platform/reduced_motion.dart';
import 'package:lschmidt_portfolio/data/repositories/asset_portfolio_repository.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/repositories/portfolio_repository.dart';
import 'package:lschmidt_portfolio/l10n/app_localizations.dart';
import 'package:lschmidt_portfolio/presentation/app_locale_x.dart';
import 'package:lschmidt_portfolio/presentation/cubits/content_cubit.dart';
import 'package:lschmidt_portfolio/presentation/cubits/locale_cubit.dart';
import 'package:lschmidt_portfolio/presentation/cubits/theme_cubit.dart';
import 'package:lschmidt_portfolio/router.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    this.initialLocation = '/',
    this.repository,
    this.reducedMotion,
  });

  final String initialLocation;
  final PortfolioRepository? repository;
  final ValueListenable<bool>? reducedMotion;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );
  late final PortfolioRepository _repository =
      widget.repository ?? AssetPortfolioRepository(rootBundle);
  late final ValueListenable<bool> _reducedMotion =
      widget.reducedMotion ?? prefersReducedMotion();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => RepositoryProvider<PortfolioRepository>.value(
    value: _repository,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocaleCubit(
            route: _router.routeInformationProvider,
            go: _router.go,
          ),
        ),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(
          create: (context) {
            final locale = context.read<LocaleCubit>();
            return ContentCubit(
              repository: _repository,
              initial: locale.state,
              locales: locale.stream,
            );
          },
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => BlocBuilder<LocaleCubit, AppLocale>(
          builder: (context, locale) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) =>
                AppLocalizations.of(context).metaTitle,
            theme: LsTheme.light(),
            darkTheme: LsTheme.dark(),
            themeMode: themeMode,
            themeAnimationDuration: LsMotion.themeFade,
            locale: locale.flutterLocale,
            supportedLocales: [
              ...AppLocalizations.supportedLocales,
              AppLocale.pt.flutterLocale,
            ],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: _router,
            builder: (context, child) => ValueListenableBuilder(
              valueListenable: _reducedMotion,
              builder: (context, reduced, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    disableAnimations: media.disableAnimations || reduced,
                  ),
                  child: child!,
                );
              },
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
