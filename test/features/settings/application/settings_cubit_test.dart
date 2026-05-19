import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/features/settings/application/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  //region state
  group("SettingsState Test", () {
    test("settings_cubit.dart export test", () {
      expect(SettingsCubit(), isA<SettingsCubit>());
    });

    test("SettingsInitial", () {
      expect(const SettingsInitial(), const SettingsInitial());
      expect(const SettingsInitial().props, [SettingsStatus.initial]);
    });
    test("SettingsLoading", () {
      expect(const SettingsLoading(), const SettingsLoading());
      expect(const SettingsLoading().props, [SettingsStatus.loading]);
    });
    test("SettingsLogoutSuccess", () {
      expect(const SettingsLogoutSuccess(), const SettingsLogoutSuccess());
      expect(const SettingsLogoutSuccess().props, [SettingsStatus.success]);
    });
    test("SettingsLanguageChanged", () {
      expect(const SettingsLanguageChanged(language: "en"), const SettingsLanguageChanged(language: "en"));
      expect(const SettingsLanguageChanged(language: "en").props, [SettingsStatus.success, "en"]);
    });
    test("SettingsThemeChanged", () {
      expect(const SettingsThemeChanged(theme: ThemeMode.system), const SettingsThemeChanged(theme: ThemeMode.system));
      expect(const SettingsThemeChanged(theme: ThemeMode.system).props, [ThemeMode.system, SettingsStatus.success]);
    });
    test("SettingsFailure", () {
      expect(const SettingsFailure(message: "Error"), const SettingsFailure(message: "Error"));
      expect(const SettingsFailure(message: "Error").props, ["Error", SettingsStatus.failure]);
    });
  });
  //endregion state

  //region cubit
  group("SettingsCubit Test", () {
    test("initial state is SettingsInitial", () {
      final cubit = SettingsCubit();
      expect(cubit.state, const SettingsInitial());
      cubit.close();
    });

    group("changeLanguage", () {
      const language = "en";
      const loadingState = SettingsLoading();
      const successState = SettingsLanguageChanged(language: language);
      const failureState = SettingsFailure(message: "Change Language Error");

      blocTest<SettingsCubit, SettingsState>(
        "emits [loading, success] when language change is successful",
        build: () => SettingsCubit(),
        act: (cubit) => cubit.changeLanguage(language),
        expect: () => [loadingState, successState],
      );

      blocTest<SettingsCubit, SettingsState>(
        "emits [loading, failure] when language change is unsuccessful",
        build: () => SettingsCubit(),
        act: (cubit) => cubit.changeLanguage(''),
        expect: () => [loadingState, failureState],
      );
    });

    group("changeTheme", () {
      const theme = ThemeMode.system;
      const loadingState = SettingsLoading();
      const successState = SettingsThemeChanged(theme: theme);

      blocTest<SettingsCubit, SettingsState>(
        "emits [loading, success] when theme change is successful",
        build: () => SettingsCubit(),
        act: (cubit) => cubit.changeTheme(theme),
        expect: () => [loadingState, successState],
      );
    });

    group("logout", () {
      const loadingState = SettingsLoading();
      const successState = SettingsLogoutSuccess();

      blocTest<SettingsCubit, SettingsState>(
        "emits [loading, success] when logout is successful",
        build: () => SettingsCubit(),
        act: (cubit) => cubit.logout(),
        expect: () => [loadingState, successState],
      );
    });
  });
  //endregion cubit
}
