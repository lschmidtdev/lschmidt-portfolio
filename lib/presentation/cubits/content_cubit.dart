import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/domain/entities/portfolio_content.dart';
import 'package:lschmidt_portfolio/domain/repositories/portfolio_repository.dart';

sealed class ContentState {
  const ContentState();
}

class ContentLoading extends ContentState {
  const ContentLoading();
}

class ContentReady extends ContentState {
  const ContentReady(this.content);

  final PortfolioContent content;
}

class ContentError extends ContentState {
  const ContentError();
}

class ContentCubit extends Cubit<ContentState> {
  ContentCubit({
    required PortfolioRepository repository,
    required AppLocale initial,
    required Stream<AppLocale> locales,
  }) : _repository = repository,
       super(const ContentLoading()) {
    _subscription = locales.listen(load);
    load(initial);
  }

  final PortfolioRepository _repository;
  late final StreamSubscription<AppLocale> _subscription;
  AppLocale? _requested;

  Future<void> load(AppLocale locale) async {
    _requested = locale;
    try {
      final content = await _repository.load(locale);
      if (_requested == locale && !isClosed) emit(ContentReady(content));
    } on Object {
      if (_requested == locale && !isClosed && state is! ContentReady) {
        emit(const ContentError());
      }
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
