import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/portfolio_content.dart';

abstract interface class PortfolioRepository {
  Future<PortfolioContent> load(AppLocale locale);
}
