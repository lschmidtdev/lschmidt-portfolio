import 'package:flutter/widgets.dart';

@immutable
class LsMotion {
  const LsMotion({required this.reduced});

  static LsMotion of(BuildContext context) =>
      LsMotion(reduced: MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  final bool reduced;

  static const reveal = Duration(milliseconds: 400);
  static const themeFade = Duration(milliseconds: 250);

  Duration movement(Duration duration) => reduced ? Duration.zero : duration;
}
