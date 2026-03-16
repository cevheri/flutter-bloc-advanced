import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc_advance/app/shell/sidebar/sidebar_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils.dart';

void main() {
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });

  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  group('SidebarEvent', () {
    group('ToggleSidebarCollapse', () {
      test('supports value equality', () {
        const event1 = ToggleSidebarCollapse();
        const event2 = ToggleSidebarCollapse();
        expect(event1, equals(event2));
      });

      test('props is empty list', () {
        const event = ToggleSidebarCollapse();
        expect(event.props, <Object?>[]);
      });

      test('is a subclass of SidebarEvent', () {
        const event = ToggleSidebarCollapse();
        expect(event, isA<SidebarEvent>());
      });

      test('toString contains class name', () {
        const event = ToggleSidebarCollapse();
        expect(event.toString(), contains('ToggleSidebarCollapse'));
      });
    });

    group('CollapseSidebar', () {
      test('supports value equality', () {
        const event1 = CollapseSidebar();
        const event2 = CollapseSidebar();
        expect(event1, equals(event2));
      });

      test('props is empty list', () {
        const event = CollapseSidebar();
        expect(event.props, <Object?>[]);
      });

      test('is a subclass of SidebarEvent', () {
        const event = CollapseSidebar();
        expect(event, isA<SidebarEvent>());
      });

      test('toString contains class name', () {
        const event = CollapseSidebar();
        expect(event.toString(), contains('CollapseSidebar'));
      });
    });

    group('ExpandSidebar', () {
      test('supports value equality', () {
        const event1 = ExpandSidebar();
        const event2 = ExpandSidebar();
        expect(event1, equals(event2));
      });

      test('props is empty list', () {
        const event = ExpandSidebar();
        expect(event.props, <Object?>[]);
      });

      test('is a subclass of SidebarEvent', () {
        const event = ExpandSidebar();
        expect(event, isA<SidebarEvent>());
      });

      test('toString contains class name', () {
        const event = ExpandSidebar();
        expect(event.toString(), contains('ExpandSidebar'));
      });
    });

    group('SetActiveRoute', () {
      test('supports value equality with same path', () {
        const event1 = SetActiveRoute('/home');
        const event2 = SetActiveRoute('/home');
        expect(event1, equals(event2));
      });

      test('is not equal when path differs', () {
        const event1 = SetActiveRoute('/home');
        const event2 = SetActiveRoute('/settings');
        expect(event1, isNot(equals(event2)));
      });

      test('props contains path', () {
        const event = SetActiveRoute('/dashboard');
        expect(event.props, ['/dashboard']);
      });

      test('path getter returns correct value', () {
        const event = SetActiveRoute('/users');
        expect(event.path, '/users');
      });

      test('is a subclass of SidebarEvent', () {
        const event = SetActiveRoute('/home');
        expect(event, isA<SidebarEvent>());
      });

      test('toString contains class name and path', () {
        const event = SetActiveRoute('/home');
        final str = event.toString();
        expect(str, contains('SetActiveRoute'));
        expect(str, contains('/home'));
      });
    });

    group('ToggleSubMenu', () {
      test('supports value equality with same menuId', () {
        const event1 = ToggleSubMenu('admin');
        const event2 = ToggleSubMenu('admin');
        expect(event1, equals(event2));
      });

      test('is not equal when menuId differs', () {
        const event1 = ToggleSubMenu('admin');
        const event2 = ToggleSubMenu('settings');
        expect(event1, isNot(equals(event2)));
      });

      test('props contains menuId', () {
        const event = ToggleSubMenu('reports');
        expect(event.props, ['reports']);
      });

      test('menuId getter returns correct value', () {
        const event = ToggleSubMenu('admin');
        expect(event.menuId, 'admin');
      });

      test('is a subclass of SidebarEvent', () {
        const event = ToggleSubMenu('admin');
        expect(event, isA<SidebarEvent>());
      });

      test('toString contains class name and menuId', () {
        const event = ToggleSubMenu('admin');
        final str = event.toString();
        expect(str, contains('ToggleSubMenu'));
        expect(str, contains('admin'));
      });
    });

    group('cross-event equality', () {
      test('different event types are not equal', () {
        const toggle = ToggleSidebarCollapse();
        const collapse = CollapseSidebar();
        const expand = ExpandSidebar();
        const setRoute = SetActiveRoute('/home');
        const toggleSub = ToggleSubMenu('admin');

        expect(toggle, isNot(equals(collapse)));
        expect(toggle, isNot(equals(expand)));
        expect(collapse, isNot(equals(expand)));
        expect(setRoute, isNot(equals(toggleSub)));
        expect(toggle, isNot(equals(setRoute)));
      });
    });
  });

  group('SidebarState', () {
    test('initial state has correct defaults', () {
      final state = SidebarState.initial();
      expect(state.isCollapsed, false);
      expect(state.activeRoute, '/');
      expect(state.expandedMenuIds, isEmpty);
    });

    test('supports value equality', () {
      final state1 = SidebarState.initial();
      final state2 = SidebarState.initial();
      expect(state1, equals(state2));
    });

    test('copyWith replaces isCollapsed', () {
      final state = SidebarState.initial();
      final updated = state.copyWith(isCollapsed: true);
      expect(updated.isCollapsed, true);
      expect(updated.activeRoute, '/');
      expect(updated.expandedMenuIds, isEmpty);
    });

    test('copyWith replaces activeRoute', () {
      final state = SidebarState.initial();
      final updated = state.copyWith(activeRoute: '/settings');
      expect(updated.isCollapsed, false);
      expect(updated.activeRoute, '/settings');
    });

    test('copyWith replaces expandedMenuIds', () {
      final state = SidebarState.initial();
      final updated = state.copyWith(expandedMenuIds: {'admin', 'reports'});
      expect(updated.expandedMenuIds, {'admin', 'reports'});
    });

    test('copyWith preserves existing values when no args given', () {
      const state = SidebarState(isCollapsed: true, activeRoute: '/users', expandedMenuIds: {'admin'});
      final copy = state.copyWith();
      expect(copy.isCollapsed, true);
      expect(copy.activeRoute, '/users');
      expect(copy.expandedMenuIds, {'admin'});
    });

    test('props contains all fields', () {
      final state = SidebarState.initial();
      expect(state.props, [false, '/', <String>{}]);
    });
  });

  group('SidebarBloc', () {
    test('initial state is SidebarState.initial()', () {
      final bloc = SidebarBloc();
      expect(bloc.state, SidebarState.initial());
      bloc.close();
    });

    blocTest<SidebarBloc, SidebarState>(
      'ToggleSidebarCollapse toggles isCollapsed from false to true',
      build: () => SidebarBloc(),
      act: (bloc) => bloc.add(const ToggleSidebarCollapse()),
      expect: () => [isA<SidebarState>().having((s) => s.isCollapsed, 'isCollapsed', true)],
    );

    blocTest<SidebarBloc, SidebarState>(
      'ToggleSidebarCollapse toggles isCollapsed from true back to false',
      build: () => SidebarBloc(),
      act: (bloc) {
        bloc.add(const ToggleSidebarCollapse());
        bloc.add(const ToggleSidebarCollapse());
      },
      expect: () => [
        isA<SidebarState>().having((s) => s.isCollapsed, 'isCollapsed', true),
        isA<SidebarState>().having((s) => s.isCollapsed, 'isCollapsed', false),
      ],
    );

    blocTest<SidebarBloc, SidebarState>(
      'CollapseSidebar sets isCollapsed to true',
      build: () => SidebarBloc(),
      act: (bloc) => bloc.add(const CollapseSidebar()),
      expect: () => [isA<SidebarState>().having((s) => s.isCollapsed, 'isCollapsed', true)],
    );

    blocTest<SidebarBloc, SidebarState>(
      'ExpandSidebar sets isCollapsed to false',
      build: () => SidebarBloc(),
      seed: () => const SidebarState(isCollapsed: true, activeRoute: '/', expandedMenuIds: {}),
      act: (bloc) => bloc.add(const ExpandSidebar()),
      expect: () => [isA<SidebarState>().having((s) => s.isCollapsed, 'isCollapsed', false)],
    );

    blocTest<SidebarBloc, SidebarState>(
      'SetActiveRoute updates activeRoute',
      build: () => SidebarBloc(),
      act: (bloc) => bloc.add(const SetActiveRoute('/dashboard')),
      expect: () => [isA<SidebarState>().having((s) => s.activeRoute, 'activeRoute', '/dashboard')],
    );

    blocTest<SidebarBloc, SidebarState>(
      'ToggleSubMenu adds menuId to expandedMenuIds',
      build: () => SidebarBloc(),
      act: (bloc) => bloc.add(const ToggleSubMenu('admin')),
      expect: () => [
        isA<SidebarState>().having((s) => s.expandedMenuIds, 'expandedMenuIds', {'admin'}),
      ],
    );

    blocTest<SidebarBloc, SidebarState>(
      'ToggleSubMenu removes menuId when already expanded',
      build: () => SidebarBloc(),
      seed: () => const SidebarState(isCollapsed: false, activeRoute: '/', expandedMenuIds: {'admin'}),
      act: (bloc) => bloc.add(const ToggleSubMenu('admin')),
      expect: () => [isA<SidebarState>().having((s) => s.expandedMenuIds, 'expandedMenuIds', <String>{})],
    );

    blocTest<SidebarBloc, SidebarState>(
      'ToggleSubMenu toggle adds then removes menuId',
      build: () => SidebarBloc(),
      act: (bloc) {
        bloc.add(const ToggleSubMenu('reports'));
        bloc.add(const ToggleSubMenu('reports'));
      },
      expect: () => [
        isA<SidebarState>().having((s) => s.expandedMenuIds, 'expandedMenuIds', {'reports'}),
        isA<SidebarState>().having((s) => s.expandedMenuIds, 'expandedMenuIds', <String>{}),
      ],
    );
  });
}
