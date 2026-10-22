import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/core/widgets/motion_aware_reveal.dart';

void main() {
  Widget page({required bool reduced, required ScrollController controller}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 400),
            disableAnimations: reduced,
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: MotionAwareReveal(
              child: Column(
                children: const [
                  SizedBox(height: 1000),
                  SizedBox(key: Key('target'), height: 50),
                ],
              ),
            ),
          ),
        ),
      );

  Future<List<double>> reveal(WidgetTester tester, ScrollController c) async {
    tester
        .renderObject(find.byKey(const Key('target')))
        .showOnScreen(duration: const Duration(milliseconds: 200));
    final positions = <double>[];
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      positions.add(c.offset);
    }
    await tester.pumpAndSettle();
    return positions;
  }

  testWidgets('follows reduced motion when it changes', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(page(reduced: false, controller: controller));

    final animated = await reveal(tester, controller);
    expect(animated.toSet().length, greaterThan(1));

    controller.jumpTo(0);
    await tester.pumpWidget(page(reduced: true, controller: controller));
    final instant = await reveal(tester, controller);
    expect(instant.first, greaterThan(0));
    expect(instant.toSet(), {instant.first});
  });
}
