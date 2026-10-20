import '../entities/app_locale.dart';
import '../entities/portfolio_content.dart';

abstract interface class PortfolioRepository {
  Future<PortfolioContent> load(AppLocale locale);
}
