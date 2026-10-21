import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/data/repositories/asset_portfolio_repository.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = AssetPortfolioRepository(rootBundle);

  group('AssetPortfolioRepository', () {
    test('loads five projects with Zsplit first and featured', () async {
      final content = await repository.load(AppLocale.en);
      expect(content.projects, hasLength(5));
      expect(content.projects.first.id, 'zsplit');
      expect(content.projects.first.featured, isTrue);
      expect(content.projects.skip(1).any((p) => p.featured), isFalse);
    });

    test('has no Play Store link until Zsplit is published', () async {
      final content = await repository.load(AppLocale.en);
      expect(content.projects.first.playStoreUrl, isNull);
    });

    test('Zirkon Labs role runs Jul 2023 to Nov 2024', () async {
      final content = await repository.load(AppLocale.en);
      final zirkon = content.roles.singleWhere(
        (r) => r.company == 'Zirkon Labs',
      );
      expect(zirkon.period, contains('Jul 2023'));
      expect(zirkon.period, contains('Nov 2024'));
    });

    test('has four metrics, roles and skill groups', () async {
      final content = await repository.load(AppLocale.en);
      expect(content.metrics, hasLength(4));
      expect(content.roles, hasLength(4));
      expect(content.skillGroups, hasLength(4));
      expect(content.roles.where((r) => r.current).single.company, 'Pulsati');
    });

    test('only Shipped carries a date', () async {
      final content = await repository.load(AppLocale.en);
      final dated = content.currently.where((c) => c.date != null).toList();
      expect(dated.map((c) => c.label), ['SHIPPED']);
      expect(dated.single.date, DateTime(2026, 10, 18));
    });

    test('loads Portuguese content', () async {
      final content = await repository.load(AppLocale.pt);
      expect(content.projects, hasLength(5));
      expect(content.profile.name, 'Lucas Schmidt');
    });
  });
}
