import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _RouteRecorder with WidgetsBindingObserver {
  final routes = <String>[];

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    routes.add(routeInformation.uri.toString());
    return Future.value(true);
  }
}

List<String> recordPushedRoutes(WidgetTester tester) {
  final recorder = _RouteRecorder();
  tester.binding.addObserver(recorder);
  addTearDown(() => tester.binding.removeObserver(recorder));
  return recorder.routes;
}

Future<void> settlePushedRoutes(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}
