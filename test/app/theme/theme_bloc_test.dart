import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/theme/theme_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme_palette.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

void main() {
  final testUtils = TestUtils();

  setUp(() async {
    await testUtils.setupUnitTest();
  });

  tearDown(() async {
    await testUtils.tearDownUnitTest();
  });

  group('ThemeState', () {
    test('default state has classic palette and system theme mode', () {
      const state = ThemeState();
      expect(state.palette, AppThemePalette.classic);
      expect(state.themeMode, ThemeMode.system);
    });

    test('copyWith updates palette', () {
      const state = ThemeState();
      final updated = state.copyWith(palette: AppThemePalette.nature);
      expect(updated.palette, AppThemePalette.nature);
      expect(updated.themeMode, ThemeMode.system);
    });

    test('copyWith updates themeMode', () {
      const state = ThemeState();
      final updated = state.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.palette, AppThemePalette.classic);
    });

    test('copyWith with no args preserves all values', () {
      const state = ThemeState(palette: AppThemePalette.sunset, themeMode: ThemeMode.dark);
      final updated = state.copyWith();
      expect(updated.palette, AppThemePalette.sunset);
      expect(updated.themeMode, ThemeMode.dark);
    });
  });

  group('ThemeEvent', () {
    test('LoadTheme can be instantiated', () {
      const event = LoadTheme();
      expect(event, isA<ThemeEvent>());
    });

    test('ChangeThemePalette holds palette', () {
      const event = ChangeThemePalette(palette: AppThemePalette.nature);
      expect(event.palette, AppThemePalette.nature);
    });

    test('ToggleBrightness can be instantiated', () {
      const event = ToggleBrightness();
      expect(event, isA<ThemeEvent>());
    });
  });

  group('ThemeBloc', () {
    test('initial state has classic palette and system theme mode', () {
      final bloc = ThemeBloc();
      expect(bloc.state.palette, AppThemePalette.classic);
      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    group('LoadTheme', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits classic palette and system mode when no preferences stored',
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.palette, 'palette', AppThemePalette.classic)
              .having((s) => s.themeMode, 'themeMode', ThemeMode.system),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits dark mode when brightness preference is dark',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.brightness.name, 'dark');
        },
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.themeMode, 'themeMode', ThemeMode.dark)
              .having((s) => s.palette, 'palette', AppThemePalette.classic),
        ],
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits light mode when brightness preference is light',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.brightness.name, 'light');
        },
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [isA<ThemeState>().having((s) => s.themeMode, 'themeMode', ThemeMode.light)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits nature palette when theme preference is nature',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.theme.name, 'nature');
        },
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [isA<ThemeState>().having((s) => s.palette, 'palette', AppThemePalette.nature)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits sunset palette when theme preference is sunset',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.theme.name, 'sunset');
        },
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [isA<ThemeState>().having((s) => s.palette, 'palette', AppThemePalette.sunset)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'defaults to classic palette for unknown theme preference',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.theme.name, 'unknown_palette');
        },
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [isA<ThemeState>().having((s) => s.palette, 'palette', AppThemePalette.classic)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'loads both dark mode and sunset palette together',
        setUp: () async {
          await AppLocalStorage().save(StorageKeys.brightness.name, 'dark');
          await AppLocalStorage().save(StorageKeys.theme.name, 'sunset');
        },
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const LoadTheme()),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.themeMode, 'themeMode', ThemeMode.dark)
              .having((s) => s.palette, 'palette', AppThemePalette.sunset),
        ],
      );
    });

    group('ChangeThemePalette', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits state with nature palette',
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ChangeThemePalette(palette: AppThemePalette.nature)),
        expect: () => [isA<ThemeState>().having((s) => s.palette, 'palette', AppThemePalette.nature)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits state with sunset palette',
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ChangeThemePalette(palette: AppThemePalette.sunset)),
        expect: () => [isA<ThemeState>().having((s) => s.palette, 'palette', AppThemePalette.sunset)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'emits state with classic palette',
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ChangeThemePalette(palette: AppThemePalette.classic)),
        expect: () => [isA<ThemeState>().having((s) => s.palette, 'palette', AppThemePalette.classic)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'persists palette to storage',
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ChangeThemePalette(palette: AppThemePalette.nature)),
        verify: (_) async {
          final stored = await AppLocalStorage().read(StorageKeys.theme.name);
          expect(stored, 'nature');
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'persists sunset palette to storage',
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ChangeThemePalette(palette: AppThemePalette.sunset)),
        verify: (_) async {
          final stored = await AppLocalStorage().read(StorageKeys.theme.name);
          expect(stored, 'sunset');
        },
      );
    });

    group('ToggleBrightness', () {
      blocTest<ThemeBloc, ThemeState>(
        'toggles from dark to light',
        seed: () => const ThemeState(themeMode: ThemeMode.dark),
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ToggleBrightness()),
        expect: () => [isA<ThemeState>().having((s) => s.themeMode, 'themeMode', ThemeMode.light)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'toggles from light to dark',
        seed: () => const ThemeState(themeMode: ThemeMode.light),
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ToggleBrightness()),
        expect: () => [isA<ThemeState>().having((s) => s.themeMode, 'themeMode', ThemeMode.dark)],
      );

      blocTest<ThemeBloc, ThemeState>(
        'persists brightness to storage when toggled to dark',
        seed: () => const ThemeState(themeMode: ThemeMode.light),
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ToggleBrightness()),
        verify: (_) async {
          final stored = await AppLocalStorage().read(StorageKeys.brightness.name);
          expect(stored, 'dark');
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'persists brightness to storage when toggled to light',
        seed: () => const ThemeState(themeMode: ThemeMode.dark),
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ToggleBrightness()),
        verify: (_) async {
          final stored = await AppLocalStorage().read(StorageKeys.brightness.name);
          expect(stored, 'light');
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'preserves palette when toggling brightness',
        seed: () => const ThemeState(palette: AppThemePalette.sunset, themeMode: ThemeMode.dark),
        build: () => ThemeBloc(),
        act: (bloc) => bloc.add(const ToggleBrightness()),
        expect: () => [
          isA<ThemeState>()
              .having((s) => s.themeMode, 'themeMode', ThemeMode.light)
              .having((s) => s.palette, 'palette', AppThemePalette.sunset),
        ],
      );
    });
  });
}
