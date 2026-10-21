import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/cubits/locale_cubit.dart';

void main() {
  late ValueNotifier<RouteInformation> route;
  late List<String> langs;
  late List<String> visited;

  LocaleCubit build(String path) {
    route = ValueNotifier(RouteInformation(uri: Uri.parse(path)));
    return LocaleCubit(route: route, go: visited.add, setLang: langs.add);
  }

  setUp(() {
    langs = [];
    visited = [];
  });

  test('/ is English and sets html lang en', () {
    final cubit = build('/');

    expect(cubit.state, AppLocale.en);
    expect(langs, ['en']);
  });

  test('/pt is Portuguese and sets html lang pt-BR', () {
    final cubit = build('/pt');

    expect(cubit.state, AppLocale.pt);
    expect(langs, ['pt-BR']);
  });

  test('unknown paths resolve to English', () {
    expect(build('/nope').state, AppLocale.en);
  });

  test('select navigates to the locale path and sets html lang', () {
    final cubit = build('/');

    cubit.select(AppLocale.pt);

    expect(visited, ['/pt']);
    expect(langs.last, 'pt-BR');
  });

  test('select of the active locale does nothing', () {
    final cubit = build('/');

    cubit.select(AppLocale.en);

    expect(visited, isEmpty);
  });

  test('follows route changes such as browser back', () {
    final cubit = build('/pt');

    route.value = RouteInformation(uri: Uri.parse('/'));

    expect(cubit.state, AppLocale.en);
    expect(langs.last, 'en');
  });
}
