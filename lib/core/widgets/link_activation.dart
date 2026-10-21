import 'package:flutter/foundation.dart';

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
