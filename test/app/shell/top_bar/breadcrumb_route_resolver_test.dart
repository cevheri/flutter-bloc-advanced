import 'package:flutter_bloc_advance/app/shell/top_bar/breadcrumb_route_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreadcrumbRouteResolver', () {
    test('root path returns Dashboard', () {
      final items = BreadcrumbRouteResolver.resolve('/');
      expect(items.length, 1);
      expect(items[0].label, 'Dashboard');
      expect(items[0].isNavigable, false);
    });

    test('empty path returns Dashboard', () {
      final items = BreadcrumbRouteResolver.resolve('');
      expect(items.length, 1);
      expect(items[0].label, 'Dashboard');
    });

    test('single segment /user returns one non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/user');
      expect(items.length, 1);
      expect(items[0].label, 'User');
      expect(items[0].isNavigable, false);
    });

    test('single segment /account returns one non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/account');
      expect(items.length, 1);
      expect(items[0].label, 'Account');
      expect(items[0].isNavigable, false);
    });

    test('single segment /settings returns one non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/settings');
      expect(items.length, 1);
      expect(items[0].label, 'Settings');
      expect(items[0].isNavigable, false);
    });

    test('/user/new returns User(navigable) > New(not navigable)', () {
      final items = BreadcrumbRouteResolver.resolve('/user/new');
      expect(items.length, 2);
      expect(items[0].label, 'User');
      expect(items[0].route, '/user');
      expect(items[0].isNavigable, true);
      expect(items[1].label, 'New');
      expect(items[1].isNavigable, false);
    });

    test('/user/:id/view collapses into User > {id}', () {
      final items = BreadcrumbRouteResolver.resolve('/user/john-doe/view');
      expect(items.length, 2);
      expect(items[0].label, 'User');
      expect(items[0].route, '/user');
      expect(items[1].label, 'John doe');
      expect(items[1].isNavigable, false);
    });

    test('/user/:id/edit returns User > {id}(view link) > Edit', () {
      final items = BreadcrumbRouteResolver.resolve('/user/john_doe/edit');
      expect(items.length, 3);
      expect(items[0].label, 'User');
      expect(items[0].route, '/user');
      expect(items[0].isNavigable, true);
      expect(items[1].label, 'John doe');
      expect(items[1].route, '/user/john_doe/view');
      expect(items[1].isNavigable, true);
      expect(items[2].label, 'Edit');
      expect(items[2].isNavigable, false);
    });

    test('strips query parameters', () {
      final items = BreadcrumbRouteResolver.resolve('/user?page=1&size=10');
      expect(items.length, 1);
      expect(items[0].label, 'User');
    });

    test('formats underscores and hyphens as spaces', () {
      final items = BreadcrumbRouteResolver.resolve('/user/new_user-4/view');
      expect(items.length, 2);
      expect(items[1].label, 'New user 4');
    });

    test('unknown feature root uses generic path', () {
      final items = BreadcrumbRouteResolver.resolve('/unknown/sub');
      expect(items.length, 2);
      expect(items[0].label, 'Unknown');
      expect(items[0].route, '/unknown');
      expect(items[1].label, 'Sub');
      expect(items[1].isNavigable, false);
    });

    test('generic fallback for deep paths', () {
      final items = BreadcrumbRouteResolver.resolve('/a/b/c/d');
      expect(items.length, 4);
      expect(items[0].route, '/a');
      expect(items[1].route, '/a/b');
      expect(items[2].route, '/a/b/c');
      expect(items[3].isNavigable, false);
    });

    test('/catalog returns single non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/catalog');
      expect(items.length, 1);
      expect(items[0].label, 'Catalog');
      expect(items[0].isNavigable, false);
    });
  });
}
