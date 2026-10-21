import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/portfolio_content.dart';
import 'package:lschmidt_portfolio/domain/repositories/portfolio_repository.dart';

class AssetPortfolioRepository implements PortfolioRepository {
  const AssetPortfolioRepository(this._bundle);

  final AssetBundle _bundle;

  @override
  Future<PortfolioContent> load(AppLocale locale) async {
    final raw = await _bundle.loadString('assets/content/${locale.name}.json');
    return PortfolioContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
