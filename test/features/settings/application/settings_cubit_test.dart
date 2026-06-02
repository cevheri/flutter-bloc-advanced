import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/features/settings/application/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  //region state
  group("SettingsState Test", () {
    test("settings_cubit.dart export test", () {
      expect(SettingsCubit(), isA<SettingsCubit>());
    });

    test("SettingsInitial", () {
      expect(const SettingsInitial(), const SettingsInitial());
      expect(const SettingsInitial().props, const <Object?>[]);
    });
    test("SettingsLoading", () {
      expect(const SettingsLoading(), const SettingsLoading());
      expect(const SettingsLoading().props, const <Object?>[]);
    });
    test("SettingsLogoutSuccess", () {
      expect(const SettingsLogoutSuccess(), const SettingsLogoutSuccess());
      expect(const SettingsLogoutSuccess().props, const <Object?>[]);
    });
    test("SettingsLanguageChanged", () {
      expect(const SettingsLanguageChanged(language: "en"), const SettingsLanguageChanged(language: "en"));
      expect(const SettingsLanguageChanged(language: "en").props, const <Object?>["en"]);
    });
    test("SettingsThemeChanged", () {
      expect(const SettingsThemeChanged(theme: ThemeMode.system), const SettingsThemeChanged(theme: ThemeMode.system));
      expect(const SettingsThemeChanged(theme: ThemeMode.system).props, const <Object?>[ThemeMode.system]);
    });
    test("SettingsFailure", () {
      expect(
        const SettingsFailure(errorCode: AppErrorCode.settingsChangeLanguageFailed, message: "Error"),
        const SettingsFailure(errorCode: AppErrorCode.settingsChangeLanguageFailed, message: "Error"),
      );
      expect(
        const SettingsFailure(errorCode: AppErrorCode.settingsChangeLanguageFailed, message: "Error").props,
        const <Object?>[AppErrorCode.settingsChangeLanguageFailed, "Error"],
      );
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
        expect: () => [
          loadingState,
          // The cubit attaches the raw exception text as message; assert
          // only on the typed errorCode for stability.
          isA<SettingsFailure>().having((s) => s.errorCode, 'errorCode', AppErrorCode.settingsChangeLanguageFailed),
        ],
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
