import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/breadcrumb_route_resolver.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreadcrumbRouteResolver', () {
    // S.load sets the process-wide Intl locale, so each test loads the language it reads.
    late S l10n;
    setUp(() async => l10n = await S.load(const Locale('en')));

    test('root path returns Dashboard', () {
      final items = BreadcrumbRouteResolver.resolve('/', l10n);
      expect(items.length, 1);
      expect(items[0].label, 'Dashboard');
      expect(items[0].isNavigable, false);
    });

    test('empty path returns Dashboard', () {
      final items = BreadcrumbRouteResolver.resolve('', l10n);
      expect(items.length, 1);
      expect(items[0].label, 'Dashboard');
    });

    test('single segment /user returns one non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/user', l10n);
      expect(items.length, 1);
      expect(items[0].label, 'Users');
      expect(items[0].isNavigable, false);
    });

    test('single segment /account returns one non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/account', l10n);
      expect(items.length, 1);
      expect(items[0].label, 'Account');
      expect(items[0].isNavigable, false);
    });

    test('single segment /settings returns one non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/settings', l10n);
      expect(items.length, 1);
      expect(items[0].label, 'Settings');
      expect(items[0].isNavigable, false);
    });

    test('/user/new returns Users(navigable) > New(not navigable)', () {
      final items = BreadcrumbRouteResolver.resolve('/user/new', l10n);
      expect(items.length, 2);
      expect(items[0].label, 'Users');
      expect(items[0].route, '/user');
      expect(items[0].isNavigable, true);
      expect(items[1].label, 'New');
      expect(items[1].isNavigable, false);
    });

    test('/user/:id/view collapses into Users > {id}', () {
      final items = BreadcrumbRouteResolver.resolve('/user/john-doe/view', l10n);
      expect(items.length, 2);
      expect(items[0].label, 'Users');
      expect(items[0].route, '/user');
      expect(items[1].label, 'John doe');
      expect(items[1].isNavigable, false);
    });

    test('/user/:id/edit returns Users > {id}(view link) > Edit', () {
      final items = BreadcrumbRouteResolver.resolve('/user/john_doe/edit', l10n);
      expect(items.length, 3);
      expect(items[0].label, 'Users');
      expect(items[0].route, '/user');
      expect(items[0].isNavigable, true);
      expect(items[1].label, 'John doe');
      expect(items[1].route, '/user/john_doe/view');
      expect(items[1].isNavigable, true);
      expect(items[2].label, 'Edit');
      expect(items[2].isNavigable, false);
    });

    // /user/{id} has no route of its own, so a link to it led to the not-found page.
    test('/user/:id/extended-info links the id to the user view page', () {
      final items = BreadcrumbRouteResolver.resolve('/user/john_doe/extended-info', l10n);
      expect(items.map((item) => item.label), ['Users', 'John doe', 'Extended Information']);
      expect(items.map((item) => item.route), ['/user', '/user/john_doe/view', null]);
    });

    test('strips query parameters', () {
      final items = BreadcrumbRouteResolver.resolve('/user?page=1&size=10', l10n);
      expect(items.length, 1);
      expect(items[0].label, 'Users');
    });

    test('formats underscores and hyphens as spaces', () {
      final items = BreadcrumbRouteResolver.resolve('/user/new_user-4/view', l10n);
      expect(items.length, 2);
      expect(items[1].label, 'New user 4');
    });

    test('unknown feature root uses generic path', () {
      final items = BreadcrumbRouteResolver.resolve('/unknown/sub', l10n);
      expect(items.length, 2);
      expect(items[0].label, 'Unknown');
      expect(items[0].route, '/unknown');
      expect(items[1].label, 'Sub');
      expect(items[1].isNavigable, false);
    });

    test('generic fallback for deep paths', () {
      final items = BreadcrumbRouteResolver.resolve('/a/b/c/d', l10n);
      expect(items.length, 4);
      expect(items[0].route, '/a');
      expect(items[1].route, '/a/b');
      expect(items[2].route, '/a/b/c');
      expect(items[3].isNavigable, false);
    });

    test('/change-password and /dynamic-forms show their page titles', () {
      expect(BreadcrumbRouteResolver.resolve('/change-password', l10n).single.label, 'Change Password');
      expect(BreadcrumbRouteResolver.resolve('/dynamic-forms', l10n).single.label, 'Dynamic Forms');
    });

    test('/catalog returns single non-navigable item', () {
      final items = BreadcrumbRouteResolver.resolve('/catalog', l10n);
      expect(items.length, 1);
      expect(items[0].label, 'Catalog');
      expect(items[0].isNavigable, false);
    });
  });
  group('BreadcrumbRouteResolver - Turkish', () {
    late S l10n;
    setUp(() async => l10n = await S.load(const Locale('tr')));

    test('labels the dashboard and the pages in Turkish', () {
      expect(BreadcrumbRouteResolver.resolve('/', l10n).single.label, 'Panel');
      expect(BreadcrumbRouteResolver.resolve('/settings', l10n).single.label, 'Ayarlar');
      expect(BreadcrumbRouteResolver.resolve('/account', l10n).single.label, 'Hesabım');
      expect(BreadcrumbRouteResolver.resolve('/change-password', l10n).single.label, 'Şifre Değiştir');
      expect(BreadcrumbRouteResolver.resolve('/dynamic-forms', l10n).single.label, 'Dinamik Formlar');
    });

    test('labels the route words in Turkish and keeps the login as it is', () {
      expect(BreadcrumbRouteResolver.resolve('/user/john_doe/edit', l10n).map((item) => item.label), [
        'Kullanıcılar',
        'John doe',
        'Düzenle',
      ]);
      expect(BreadcrumbRouteResolver.resolve('/user/new', l10n).map((item) => item.label), ['Kullanıcılar', 'Yeni']);
      expect(BreadcrumbRouteResolver.resolve('/user/john_doe/extended-info', l10n).last.label, 'Genişletilmiş Bilgi');
    });

    test('keeps a login or a form id that matches a route word as it is', () {
      expect(BreadcrumbRouteResolver.resolve('/user/user/extended-info', l10n).map((item) => item.label), [
        'Kullanıcılar',
        'User',
        'Genişletilmiş Bilgi',
      ]);
      expect(BreadcrumbRouteResolver.resolve('/user/account/extended-info', l10n).map((item) => item.label), [
        'Kullanıcılar',
        'Account',
        'Genişletilmiş Bilgi',
      ]);
      expect(BreadcrumbRouteResolver.resolve('/dynamic-forms/new', l10n).map((item) => item.label), [
        'Dinamik Formlar',
        'New',
      ]);
    });
  });
}
