import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

ValueListenable<bool> prefersReducedMotion() {
  final query = web.window.matchMedia('(prefers-reduced-motion: reduce)');
  final notifier = ValueNotifier(query.matches);
  query.addEventListener(
    'change',
    ((web.MediaQueryListEvent event) {
      notifier.value = event.matches;
    }).toJS,
  );
  return notifier;
}
