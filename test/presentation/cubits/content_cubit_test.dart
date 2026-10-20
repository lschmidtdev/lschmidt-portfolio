import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/cubits/content_cubit.dart';

import '../../helpers/fake_portfolio_repository.dart';

void main() {
  test(
    'emits Ready for the initial locale and reloads on locale change',
    () async {
      final repository = FakePortfolioRepository();
      final locales = StreamController<AppLocale>();
      final cubit = ContentCubit(
        repository: repository,
        initial: AppLocale.en,
        locales: locales.stream,
      );

      expect(cubit.state, isA<ContentLoading>());
      await Future<void>.delayed(Duration.zero);
      final english = cubit.state as ContentReady;
      expect(english.content.profile.name, 'Lucas Schmidt');
      expect(repository.loaded, [AppLocale.en]);

      locales.add(AppLocale.pt);
      await Future<void>.delayed(Duration.zero);
      expect(repository.loaded, [AppLocale.en, AppLocale.pt]);
      final portuguese = cubit.state as ContentReady;
      expect(
        portuguese.content.profile.role,
        isNot(english.content.profile.role),
      );

      await cubit.close();
      await locales.close();
    },
  );

  test('emits Error when the repository fails', () async {
    final cubit = ContentCubit(
      repository: FakePortfolioRepository(failing: true),
      initial: AppLocale.en,
      locales: const Stream.empty(),
    );

    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<ContentError>());
    await cubit.close();
  });
}
