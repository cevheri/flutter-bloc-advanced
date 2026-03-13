import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/features/settings/application/usecases/change_theme_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ChangeThemeUseCase useCase;

  setUp(() {
    useCase = const ChangeThemeUseCase();
  });

  test('returns the provided theme mode', () {
    expect(useCase.call(ThemeMode.dark), ThemeMode.dark);
    expect(useCase.call(ThemeMode.light), ThemeMode.light);
    expect(useCase.call(ThemeMode.system), ThemeMode.system);
  });
}
