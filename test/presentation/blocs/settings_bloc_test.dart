import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/presentation/screen/settings/bloc/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils.dart';

/// SettingsBlocTest
///
/// Tests: <p>
/// state
/// event
/// bloc
void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  //region state
  /// Settings State Tests
  group("SettingsState Test", () {
    test("settings.dart export test", () {
      expect(SettingsBloc(), isA<SettingsBloc>());
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
      expect(
        const SettingsThemeChanged(theme: AdaptiveThemeMode.system),
        const SettingsThemeChanged(theme: AdaptiveThemeMode.system),
      );
      expect(const SettingsThemeChanged(theme: AdaptiveThemeMode.system).props, [
        AdaptiveThemeMode.system,
        SettingsStatus.success,
      ]);
    });
    test("SettingsFailure", () {
      expect(const SettingsFailure(message: "Error"), const SettingsFailure(message: "Error"));
      expect(const SettingsFailure(message: "Error").props, ["Error", SettingsStatus.failure]);
    });
  });

  //endregion state

  //region event
  /// Settings Event Tests
  group("SettingsEvent Test", () {
    test("Logout", () {
      expect(Logout(), Logout());
      expect(Logout().props, []);
    });
    test("ChangeLanguage", () {
      expect(const ChangeLanguage(language: "en"), const ChangeLanguage(language: "en"));
      expect(const ChangeLanguage(language: "en").props, ["en"]);
    });
    test("ChangeTheme", () {
      expect(const ChangeTheme(theme: AdaptiveThemeMode.system), const ChangeTheme(theme: AdaptiveThemeMode.system));
      expect(const ChangeTheme(theme: AdaptiveThemeMode.system).props, [AdaptiveThemeMode.system]);
    });
  });

  //endregion event

  //region bloc
  /// Settings Bloc Tests
  group("SettingsBloc Test", () {
    test("SettingsBloc", () {
      final bloc = SettingsBloc();
      expect(bloc.state, const SettingsInitial());
      bloc.close();
    });

    group("ChangeLanguage", () {
      const language = "en";
      const event = ChangeLanguage(language: language);
      const loadingState = SettingsLoading();
      const successState = SettingsLanguageChanged(language: language);
      const failureState = SettingsFailure(message: "Change Language Error");

      final statesSuccess = [loadingState, successState];
      final statesFailure = [loadingState, failureState];

      blocTest<SettingsBloc, SettingsState>(
        "emits [loading, success] when submit is successful",
        build: () => SettingsBloc(),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );

      blocTest<SettingsBloc, SettingsState>(
        "emits [loading, failure] when submit is unsuccessful",
        build: () => SettingsBloc(),
        act: (bloc) => bloc..add(const ChangeLanguage(language: '')),
        expect: () => statesFailure,
      );
    });

    group("ChangeTheme", () {
      const theme = AdaptiveThemeMode.system;
      const event = ChangeTheme(theme: theme);
      const loadingState = SettingsLoading();
      const successState = SettingsThemeChanged(theme: theme);

      final statesSuccess = [loadingState, successState];

      blocTest<SettingsBloc, SettingsState>(
        "emits [loading, success] when submit is successful",
        build: () => SettingsBloc(),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );
    });

    group("Logout", () {
      final event = Logout();
      const loadingState = SettingsLoading();
      const successState = SettingsLogoutSuccess();

      final statesSuccess = [loadingState, successState];

      blocTest<SettingsBloc, SettingsState>(
        "emits [loading, success] when submit is successful",
        build: () => SettingsBloc(),
        act: (bloc) => bloc..add(event),
        expect: () => statesSuccess,
      );
    });
  });
  //endregion bloc
}
