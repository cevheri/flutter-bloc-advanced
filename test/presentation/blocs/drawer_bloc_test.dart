import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/data/models/menu.dart';
import 'package:flutter_bloc_advance/data/repository/login_repository.dart';
import 'package:flutter_bloc_advance/data/repository/menu_repository.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/drawer/drawer_bloc/drawer.dart';
import 'package:flutter_bloc_advance/utils/menu_list_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_utils.dart';
import 'drawer_bloc_test.mocks.dart';

/// BLoc Test for DrawerBloc
///
/// Tests: <p>
/// 1. State test <p>
/// 2. Event test <p>
/// 3. Bloc test <p>
@GenerateMocks([LoginRepository, MenuRepository])
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
  /// Drawer State Tests
  group("DrawerState", () {
    const menus = [Menu(id: "test", name: "test")];
    const isLogout = false;

    test("supports value comparisons", () {
      expect(const DrawerState(menus: menus, isLogout: isLogout), const DrawerState(menus: menus, isLogout: isLogout));
    });

    test("DrawerState copyWith", () {
      expect(const DrawerState().copyWith(), const DrawerState());
      expect(const DrawerState().copyWith(menus: menus), const DrawerState(menus: menus));
    });
  });
  //endregion state

  //region event
  /// Drawer Event Tests
  group("DrawerEvent", () {
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
  /// Drawer Bloc Tests
  group("Drawer Bloc", () {
    group("LoadMenu", () {
      tearDown(() {
        MenuListCache.menus = [];
      });
      const input = [Menu(id: "test", name: "test")];
      final output = Future.value(input);
      const event = LoadMenus(language: "en");
      const loadingState = DrawerState(menus: [], status: DrawerStateStatus.loading);
      const successState = DrawerState(menus: input, status: DrawerStateStatus.success, language: 'en');
      const failureState = DrawerState(menus: [], status: DrawerStateStatus.error, language: 'en');
      blocTest<DrawerBloc, DrawerState>(
        "emits [loading, success] when LoadMenus is added",
        setUp: () {
          when(menuRepository.list()).thenAnswer((_) => output);
          MenuListCache.menus = [];
        },
        build: () => DrawerBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<DrawerBloc, DrawerState>(
        "emits [loading, failure] when LoadMenus is added",
        setUp: () {
          when(menuRepository.list()).thenThrow(Exception("Error"));
          MenuListCache.menus = [];
        },
        build: () => DrawerBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
      );
    });

    group("RefreshMenu", () {
      const input = [Menu(id: "test", name: "test")];
      final output = Future.value(input);
      final event = RefreshMenus();
      const loadingState = DrawerState(menus: [], status: DrawerStateStatus.loading);
      const successState = DrawerState(menus: input, status: DrawerStateStatus.success);
      const failureState = DrawerState(menus: [], status: DrawerStateStatus.error);
      blocTest<DrawerBloc, DrawerState>(
        "emits [loading, success] when RefreshMenus is added",
        setUp: () {
          when(menuRepository.list()).thenAnswer((_) => output);
          MenuListCache.menus = [];
        },
        build: () => DrawerBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<DrawerBloc, DrawerState>(
        "emits [loading, failure] when RefreshMenus is added",
        setUp: () {
          when(menuRepository.list()).thenThrow(Exception("Error"));
          MenuListCache.menus = [];
        },
        build: () => DrawerBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
      );
    });

    group("Logout", () {
      final event = Logout();
      const loadingState = DrawerState(status: DrawerStateStatus.loading);
      const successState = DrawerState(status: DrawerStateStatus.success, isLogout: true);
      const failureState = DrawerState(status: DrawerStateStatus.error);
      blocTest<DrawerBloc, DrawerState>(
        "emits [success] when Logout is added",
        setUp: () {
          when(loginRepository.logout()).thenAnswer((_) => Future.value());
          MenuListCache.menus = [];
        },
        build: () => DrawerBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, successState],
      );

      blocTest<DrawerBloc, DrawerState>(
        "emits [success] when Logout is added",
        setUp: () {
          when(loginRepository.logout()).thenThrow(Exception("Error"));
          MenuListCache.menus = [];
        },
        build: () => DrawerBloc(loginRepository: loginRepository, menuRepository: menuRepository),
        act: (bloc) => bloc..add(event),
        expect: () => [loadingState, failureState],
      );
    });
  });
}
