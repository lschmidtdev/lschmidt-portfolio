import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> mockUrlLauncher(WidgetTester tester) {
  final launched = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (call) async {
      if (call.method == 'launch') {
        launched.add((call.arguments as Map)['url'] as String);
      }
      return true;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    ),
  );
  return launched;
}

Future<void> tapIgnoringLaunchErrors(WidgetTester tester, Finder finder) async {
  final done = Completer<void>();
  runZonedGuarded(
    () => tester.tap(finder).then((_) => done.complete()),
    (_, _) {},
  );
  await done.future;
  await tester.pump();
}
