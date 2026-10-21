import 'dart:convert';
import 'dart:io';

import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/portfolio_content.dart';
import 'package:lschmidt_portfolio/domain/repositories/portfolio_repository.dart';

class FakePortfolioRepository implements PortfolioRepository {
  FakePortfolioRepository({this.failing = false});

  final bool failing;
  final loaded = <AppLocale>[];

  static PortfolioContent contentFor(AppLocale locale) =>
      PortfolioContent.fromJson(
        jsonDecode(
              File('assets/content/${locale.name}.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );

  @override
  Future<PortfolioContent> load(AppLocale locale) async {
    loaded.add(locale);
    if (failing) throw StateError('load failed');
    return contentFor(locale);
  }
}
