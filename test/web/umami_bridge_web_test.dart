@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/data/sources/umami_bridge.dart';

void _throwing() {
  throw StateError('x');
}

void main() {
  tearDown(() => globalContext.delete('umami'.toJS));

  test('does nothing and throws nothing when window.umami is undefined', () {
    globalContext.delete('umami'.toJS);
    expect(() => umamiTrack('cv_download'), returnsNormally);
  });

  test('does nothing when window.umami is not an object', () {
    globalContext['umami'] = 'blocked'.toJS;
    expect(() => umamiTrack('cv_download'), returnsNormally);
  });

  test('does nothing when track is missing or throws', () {
    globalContext['umami'] = JSObject();
    expect(() => umamiTrack('cv_download'), returnsNormally);
    final failing = JSObject();
    failing['track'] = _throwing.toJS;
    globalContext['umami'] = failing;
    expect(() => umamiTrack('cv_download'), returnsNormally);
  });

  test('calls window.umami.track with the event name once', () {
    final calls = <String>[];
    final umami = JSObject();
    umami['track'] = ((JSString name) => calls.add(name.toDart)).toJS;
    globalContext['umami'] = umami;
    umamiTrack('email_app_opened');
    expect(calls, ['email_app_opened']);
  });
}
