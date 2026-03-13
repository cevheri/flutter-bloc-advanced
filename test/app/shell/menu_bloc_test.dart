import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/app/shell/models/menu.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_list_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';
import '../../test_utils.dart';

/// BLoc Test for MenuBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
void main() {
  //region setup
  late LoginRepository loginRepository;
  late MenuRepository menuRepository;

  setUpAll(() async {
    await TestUtils().setupUnitTest();
    loginRepository = MockLoginRepository();
    menuRepository = MockMenuRepository();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });
  //endregion setup

  //region state
  /// Menu State Tests
  group("MenuState", () {
    const menus = [Menu(id: "test", name: "test")];
    const isLogout = false;

    test("supports value comparisons", () {
      expect(const MenuState(menus: menus, isLogout: isLogout), const MenuState(menus: menus, isLogout: isLogout));
    });

    test("MenuState copyWith", () {
      expect(const MenuState().copyWith(), const MenuState());
      expect(const MenuState().copyWith(menus: menus), const MenuState(menus: menus));
    });
  });
  //endregion state

  //region event
  /// Menu Event Tests
  group("MenuEvent", () {
    test("supports value comparisons", () {
      expect(const LoadMenus(language: "en"), const LoadMenus(language: "en"));
      expect(RefreshMenus(), RefreshMenus());
      expect(Logout(), Logout());
    });
    test("props", () {
      expect(const LoadMenus(language: "en").props, ['en']);
      expect(RefreshMenus().props, []);
      expect(Logout().props, []);
    });
  });
  //endregion event

  //region bloc
  /// Menu Bloc Tests
  group("Menu Bloc", () {
    group("LoadMenu", () {
      tearDown(() {
        MenuListCache.menus = [];
      });
      const input = [Menu(id: "test", name: "test")];
      final output = Future.value(input);
      const event = LoadMenus(language: "en");
      const loadingState = MenuState(menus: [], status: MenuStateStatus.loading);
      const successState = MenuState(menus: input, status: MenuStateStatus.success, language: 'en');
      const failureState = MenuState(menus: [], status: MenuStateStatus.error, language: 'en');
      blocTest<MenuBloc, MenuState>(
        "emits [loading, success] when LoadMenus is added",
        setUp: () {
          when(() => menuRepository.list()).thenAnswer((_) => output);
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<MenuBloc, MenuState>(
        "emits [loading, failure] when LoadMenus is added",
        setUp: () {
          when(() => menuRepository.list()).thenThrow(Exception("Error"));
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
      );
    });

    group("RefreshMenu", () {
      const input = [Menu(id: "test", name: "test")];
      final output = Future.value(input);
      final event = RefreshMenus();
      const loadingState = MenuState(menus: [], status: MenuStateStatus.loading);
      const successState = MenuState(menus: input, status: MenuStateStatus.success);
      const failureState = MenuState(menus: [], status: MenuStateStatus.error);
      blocTest<MenuBloc, MenuState>(
        "emits [loading, success] when RefreshMenus is added",
        setUp: () {
          when(() => menuRepository.list()).thenAnswer((_) => output);
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<MenuBloc, MenuState>(
        "emits [loading, failure] when RefreshMenus is added",
        setUp: () {
          when(() => menuRepository.list()).thenThrow(Exception("Error"));
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
      );
    });

    group("Logout", () {
      final event = Logout();
      const loadingState = MenuState(status: MenuStateStatus.loading);
      const successState = MenuState(status: MenuStateStatus.success, isLogout: true);
      const failureState = MenuState(status: MenuStateStatus.error);
      blocTest<MenuBloc, MenuState>(
        "emits [success] when Logout is added",
        setUp: () {
          when(() => loginRepository.logout()).thenAnswer((_) => Future.value(const Success<void>(null)));
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<MenuBloc, MenuState>(
        "emits [failure] when Logout fails",
        setUp: () {
          when(
            () => loginRepository.logout(),
          ).thenAnswer((_) => Future.value(const Failure<void>(UnknownError("Error"))));
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
      );
    });
  });
}
