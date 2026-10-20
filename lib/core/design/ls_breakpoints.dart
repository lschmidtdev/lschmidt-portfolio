import 'package:flutter/widgets.dart';

enum LsSize { phone, tablet, desktop }

abstract final class LsBreakpoints {
  static const phone = 600.0;
  static const tablet = 1024.0;

  static LsSize forWidth(double width) {
    if (width >= tablet) return LsSize.desktop;
    if (width >= phone) return LsSize.tablet;
    return LsSize.phone;
  }

  static LsSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);
}
