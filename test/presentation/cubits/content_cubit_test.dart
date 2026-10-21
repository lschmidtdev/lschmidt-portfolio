import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/portfolio_content.dart';
import 'package:lschmidt_portfolio/domain/repositories/portfolio_repository.dart';
import 'package:lschmidt_portfolio/presentation/cubits/content_cubit.dart';

import '../../helpers/fake_portfolio_repository.dart';

class _GatedRepository implements PortfolioRepository {
  final gates = <AppLocale, Completer<PortfolioContent>>{};

  Completer<PortfolioContent> gate(AppLocale locale) =>
      gates.putIfAbsent(locale, Completer.new);

  @override
  Future<PortfolioContent> load(AppLocale locale) => gate(locale).future;
}

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

  test('keeps the previous content while a new locale loads', () async {
    final repository = _GatedRepository();
    final locales = StreamController<AppLocale>();
    final cubit = ContentCubit(
      repository: repository,
      initial: AppLocale.en,
      locales: locales.stream,
    );
    final english = FakePortfolioRepository.contentFor(AppLocale.en);
    final portuguese = FakePortfolioRepository.contentFor(AppLocale.pt);
    final emitted = <ContentState>[];
    final subscription = cubit.stream.listen(emitted.add);

    repository.gate(AppLocale.en).complete(english);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as ContentReady).content, same(english));

    locales.add(AppLocale.pt);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<ContentReady>());
    expect((cubit.state as ContentReady).content, same(english));

    repository.gate(AppLocale.pt).complete(portuguese);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as ContentReady).content, same(portuguese));
    expect(emitted.whereType<ContentLoading>(), isEmpty);

    await subscription.cancel();
    await cubit.close();
    await locales.close();
  });

  test('keeps the previous content when a reload fails', () async {
    final repository = _GatedRepository();
    final locales = StreamController<AppLocale>();
    final cubit = ContentCubit(
      repository: repository,
      initial: AppLocale.en,
      locales: locales.stream,
    );
    final english = FakePortfolioRepository.contentFor(AppLocale.en);
    repository.gate(AppLocale.en).complete(english);
    await Future<void>.delayed(Duration.zero);

    locales.add(AppLocale.pt);
    repository.gate(AppLocale.pt).completeError(StateError('offline'));
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as ContentReady).content, same(english));
    await cubit.close();
    await locales.close();
  });

  test('ignores a slow load that a newer locale superseded', () async {
    final repository = _GatedRepository();
    final locales = StreamController<AppLocale>();
    final cubit = ContentCubit(
      repository: repository,
      initial: AppLocale.en,
      locales: locales.stream,
    );
    final english = FakePortfolioRepository.contentFor(AppLocale.en);
    final portuguese = FakePortfolioRepository.contentFor(AppLocale.pt);

    locales.add(AppLocale.pt);
    await Future<void>.delayed(Duration.zero);
    repository.gate(AppLocale.pt).complete(portuguese);
    await Future<void>.delayed(Duration.zero);
    repository.gate(AppLocale.en).complete(english);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as ContentReady).content, same(portuguese));
    await cubit.close();
    await locales.close();
  });

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
