import 'dart:async';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

VoidCallback? withActivation(
  VoidCallback? followLink,
  VoidCallback? onActivated,
) {
  if (followLink == null) return null;
  return () {
    try {
      onActivated?.call();
    } finally {
      followLink();
    }
  };
}

bool get _opensElsewhere {
  final keys = HardwareKeyboard.instance;
  return keys.isControlPressed || keys.isMetaPressed || keys.isShiftPressed;
}

VoidCallback? inPageActivation(
  VoidCallback? followLink,
  VoidCallback? onActivated,
  Uri href,
) {
  if (followLink == null) return null;
  return () {
    if (!_opensElsewhere) return onActivated?.call();
    unawaited(
      launchUrl(Uri.base.resolveUri(href), webOnlyWindowName: '_blank'),
    );
  };
}
