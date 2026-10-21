import 'package:go_router/go_router.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/pages/home_page.dart';
import 'package:lschmidt_portfolio/routes.dart';

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) => redirectFor(state.uri.path),
  routes: [
    for (final locale in AppLocale.values)
      GoRoute(
        path: locale.path,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomePage()),
      ),
  ],
);
