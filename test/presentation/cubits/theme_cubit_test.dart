import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/presentation/cubits/theme_cubit.dart';

void main() {
  test('starts dark', () {
    expect(ThemeCubit().state, ThemeMode.dark);
  });

  blocTest<ThemeCubit, ThemeMode>(
    'toggle switches between dark and light',
    build: ThemeCubit.new,
    act: (cubit) => cubit
      ..toggle()
      ..toggle(),
    expect: () => [ThemeMode.light, ThemeMode.dark],
  );
}
