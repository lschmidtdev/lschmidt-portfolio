import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void umamiTrack(String eventName) {
  try {
    final umami = globalContext['umami'];
    if (!umami.isA<JSObject>()) return;
    (umami as JSObject).callMethod('track'.toJS, eventName.toJS);
  } on Object {
    return;
  }
}
