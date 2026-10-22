import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class MotionAwareReveal extends SingleChildRenderObjectWidget {
  const MotionAwareReveal({super.key, super.child});

  @override
  RenderMotionAwareReveal createRenderObject(BuildContext context) =>
      RenderMotionAwareReveal(instant: MediaQuery.disableAnimationsOf(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMotionAwareReveal renderObject,
  ) {
    renderObject.instant = MediaQuery.disableAnimationsOf(context);
  }
}

class RenderMotionAwareReveal extends RenderProxyBox {
  RenderMotionAwareReveal({required this.instant});

  bool instant;

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    super.showOnScreen(
      descendant: descendant,
      rect: rect,
      duration: instant ? Duration.zero : duration,
      curve: curve,
    );
  }
}
