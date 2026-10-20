import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/app/shell/models/menu.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/logout_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_list_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_classes.dart';

/// BLoc Test for MenuBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
void main() {
  //region setup
  late IAuthRepository authRepository;
  late MenuRepository menuRepository;

  setUpAll(() {
    authRepository = MockIAuthRepository();
    menuRepository = MockMenuRepository();
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
      expect(const LoadMenus(), const LoadMenus());
      expect(RefreshMenus(), RefreshMenus());
      expect(Logout(), Logout());
    });
    test("props", () {
      expect(const LoadMenus().props, []);
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
      const event = LoadMenus();
      const loadingState = MenuState(menus: [], status: MenuStateStatus.loading);
      const successState = MenuState(menus: input, status: MenuStateStatus.success);
      const failureState = MenuState(menus: [], status: MenuStateStatus.error);
      blocTest<MenuBloc, MenuState>(
        "emits [loading, success] when LoadMenus is added",
        setUp: () {
          when(() => menuRepository.list()).thenAnswer((_) => output);
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(logoutUseCase: LogoutUseCase(authRepository), menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<MenuBloc, MenuState>(
        "emits [loading, failure] when LoadMenus is added",
        setUp: () {
          when(() => menuRepository.list()).thenThrow(Exception("Error"));
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(logoutUseCase: LogoutUseCase(authRepository), menuRepository: menuRepository),
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
        build: () => MenuBloc(logoutUseCase: LogoutUseCase(authRepository), menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<MenuBloc, MenuState>(
        "emits [loading, failure] when RefreshMenus is added",
        setUp: () {
          when(() => menuRepository.list()).thenThrow(Exception("Error"));
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(logoutUseCase: LogoutUseCase(authRepository), menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
      );
    });

    group("Logout", () {
      final event = Logout();
      const loadingState = MenuState(status: MenuStateStatus.loading);
      const successState = MenuState(status: MenuStateStatus.success, isLogout: true);
      const failureState = MenuState(status: MenuStateStatus.error, isLogout: true);
      blocTest<MenuBloc, MenuState>(
        "emits [success] when Logout is added",
        setUp: () {
          when(() => authRepository.logout()).thenAnswer((_) => Future.value(const Success<void>(null)));
          MenuListCache.menus = [];
        },
        build: () => MenuBloc(logoutUseCase: LogoutUseCase(authRepository), menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
        verify: (_) => verify(() => authRepository.logout()).called(1),
      );

      // As SessionCubit.endSession does, the logout ends the session even when it cannot clear all that it stored.
      blocTest<MenuBloc, MenuState>(
        "signs out with the error status when the logout cannot clear the stored session",
        setUp: () {
          when(() => authRepository.logout())
              .thenAnswer((_) => Future.value(const Failure<void>(UnknownError("Error"))));
          MenuListCache.menus = [const Menu(id: "test", name: "test")];
        },
        build: () => MenuBloc(logoutUseCase: LogoutUseCase(authRepository), menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
        verify: (_) => expect(MenuListCache.menus, isEmpty),
      );
    });
  });
}
