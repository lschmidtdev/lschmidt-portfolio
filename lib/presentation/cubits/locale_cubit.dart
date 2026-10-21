import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:lschmidt_portfolio/core/platform/document_lang.dart';
import 'package:lschmidt_portfolio/domain/entities/app_locale.dart';
import 'package:lschmidt_portfolio/presentation/app_locale_x.dart';
import 'package:lschmidt_portfolio/routes.dart';

class LocaleCubit extends Cubit<AppLocale> {
  LocaleCubit({
    required ValueListenable<RouteInformation> route,
    required void Function(String location) go,
    void Function(String lang) setLang = setDocumentLang,
  }) : _route = route,
       _go = go,
       _setLang = setLang,
       super(localeForPath(route.value.uri.path)) {
    _setLang(state.htmlLang);
    _route.addListener(_follow);
  }

  final ValueListenable<RouteInformation> _route;
  final void Function(String location) _go;
  final void Function(String lang) _setLang;

  void _follow() {
    final next = localeForPath(_route.value.uri.path);
    if (next != state) emit(next);
  }

  void select(AppLocale locale) {
    if (locale == state) return;
    _setLang(locale.htmlLang);
    _go(locale.path);
  }

  @override
  void onChange(Change<AppLocale> change) {
    super.onChange(change);
    _setLang(change.nextState.htmlLang);
  }

  @override
  Future<void> close() {
    _route.removeListener(_follow);
    return super.close();
  }
}
