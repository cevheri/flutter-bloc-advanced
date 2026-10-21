import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/app/shell/models/menu.dart';
import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/errors/app_error_code.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/logout_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/application/usecases/sso_sign_out_usecase.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc_advance/features/auth/domain/repositories/sso_sign_out_repository.dart';
import 'package:flutter_bloc_advance/app/shell/repositories/menu_repository.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_list_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mock_classes.dart';

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

      // In an oidc build the app session has ended, but the provider logout failed.
      blocTest<MenuBloc, MenuState>(
        "signs out with the providerSessionLeft status when the provider logout is incomplete",
        setUp: () {
          when(() => authRepository.logout()).thenAnswer(
            (_) => Future.value(
              Failure<void>(AuthError('provider logout incomplete', code: AppErrorCode.authOidcLogoutIncomplete.key)),
            ),
          );
          MenuListCache.menus = [const Menu(id: "test", name: "test")];
        },
        build: () => MenuBloc(logoutUseCase: LogoutUseCase(authRepository), menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, const MenuState(status: MenuStateStatus.providerSessionLeft, isLogout: true)],
        verify: (_) => expect(MenuListCache.menus, isEmpty),
      );
    });

    // In an oidc build the provider logout can wait for the browser for minutes, so the sign-out does not wait for it.
    group("Logout in an oidc build", () {
      late _FakeSsoSignOutRepository signOut;
      late MockIAuthRepository passwordLogout;
      const loadingState = MenuState(menus: [], status: MenuStateStatus.loading);
      const signedOut = MenuState(status: MenuStateStatus.success, isLogout: true);
      final incomplete = Failure<void>(
        AuthError('provider logout incomplete', code: AppErrorCode.authOidcLogoutIncomplete.key),
      );

      setUp(() {
        signOut = _FakeSsoSignOutRepository();
        passwordLogout = MockIAuthRepository();
        MenuListCache.menus = [const Menu(id: "test", name: "test")];
      });
      tearDown(() => MenuListCache.menus = []);

      MenuBloc build() => MenuBloc(
        logoutUseCase: LogoutUseCase(passwordLogout),
        menuRepository: menuRepository,
        ssoSignOutUseCase: SsoSignOutUseCase(signOut),
      );

      blocTest<MenuBloc, MenuState>(
        "signs out once the session on this device is cleared, while the provider logout has not ended",
        build: build,
        act: (bloc) => bloc.add(Logout()),
        expect: () => [loadingState, signedOut],
        verify: (_) {
          expect(MenuListCache.menus, isEmpty);
          verifyNever(() => passwordLogout.logout());
        },
      );

      blocTest<MenuBloc, MenuState>(
        "then sets the providerSessionLeft status when the provider logout fails",
        build: build,
        act: (bloc) async {
          bloc.add(Logout());
          await Future<void>.delayed(Duration.zero);
          signOut.providerLogout.complete(incomplete);
        },
        expect: () => [
          loadingState,
          signedOut,
          const MenuState(status: MenuStateStatus.providerSessionLeft, isLogout: true),
        ],
      );

      blocTest<MenuBloc, MenuState>(
        "keeps the success status when the provider session ends",
        build: build,
        act: (bloc) async {
          bloc.add(Logout());
          await Future<void>.delayed(Duration.zero);
          signOut.providerLogout.complete(const Success(null));
        },
        expect: () => [loadingState, signedOut],
      );

      // The data left on this device is the more serious of the two, and the user can only be told one of them.
      blocTest<MenuBloc, MenuState>(
        "keeps the error status of a failed wipe when the provider logout fails too",
        setUp: () => signOut.cleared = const Failure<void>(UnknownError('Session clear failed: jwtToken')),
        build: build,
        act: (bloc) async {
          bloc.add(Logout());
          await Future<void>.delayed(Duration.zero);
          signOut.providerLogout.complete(incomplete);
        },
        expect: () => [loadingState, const MenuState(status: MenuStateStatus.error, isLogout: true)],
      );
    });
  });
}

/// The logout of an oidc build: the session on this device is cleared with [cleared], and the provider logout ends
/// when the test completes [providerLogout].
class _FakeSsoSignOutRepository implements ISsoSignOutRepository {
  Result<void> cleared = const Success(null);
  final providerLogout = Completer<Result<void>>();

  @override
  Future<SsoSignOut> signOut() async => SsoSignOut(cleared: cleared, providerLogout: providerLogout.future);
}
