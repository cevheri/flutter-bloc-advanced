import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/utils/icon_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getIconFromString', () {
    group('known icon mappings', () {
      test('home returns Icons.home', () {
        expect(getIconFromString('home'), Icons.home);
      });

      test('dashboard returns Icons.dashboard', () {
        expect(getIconFromString('dashboard'), Icons.dashboard);
      });

      test('settings returns Icons.settings', () {
        expect(getIconFromString('settings'), Icons.settings);
      });

      test('user returns Icons.person', () {
        expect(getIconFromString('user'), Icons.person);
      });

      test('login returns Icons.login', () {
        expect(getIconFromString('login'), Icons.login);
      });

      test('logout returns Icons.logout', () {
        expect(getIconFromString('logout'), Icons.logout);
      });

      test('search returns Icons.search', () {
        expect(getIconFromString('search'), Icons.search);
      });

      test('edit returns Icons.edit', () {
        expect(getIconFromString('edit'), Icons.edit);
      });

      test('delete returns Icons.delete', () {
        expect(getIconFromString('delete'), Icons.delete);
      });

      test('add returns Icons.add', () {
        expect(getIconFromString('add'), Icons.add);
      });

      test('notifications returns Icons.notifications', () {
        expect(getIconFromString('notifications'), Icons.notifications);
      });

      test('help returns Icons.help', () {
        expect(getIconFromString('help'), Icons.help);
      });

      test('info returns Icons.info', () {
        expect(getIconFromString('info'), Icons.info);
      });

      test('warning returns Icons.warning', () {
        expect(getIconFromString('warning'), Icons.warning);
      });

      test('error returns Icons.error', () {
        expect(getIconFromString('error'), Icons.error);
      });

      test('success returns Icons.check_circle', () {
        expect(getIconFromString('success'), Icons.check_circle);
      });
    });

    group('alias icon mappings', () {
      test('account-tie returns Icons.account_circle', () {
        expect(getIconFromString('account-tie'), Icons.account_circle);
      });

      test('account returns Icons.account_circle', () {
        expect(getIconFromString('account'), Icons.account_circle);
      });

      test('cog-outline returns Icons.settings', () {
        expect(getIconFromString('cog-outline'), Icons.settings);
      });

      test('account-edit-outline returns Icons.edit', () {
        expect(getIconFromString('account-edit-outline'), Icons.edit);
      });

      test('account-multiple-plus-outline returns Icons.add', () {
        expect(getIconFromString('account-multiple-plus-outline'), Icons.add);
      });
    });

    group('category-specific icons', () {
      test('favorite returns Icons.favorite', () {
        expect(getIconFromString('favorite'), Icons.favorite);
      });

      test('bookmark returns Icons.bookmark', () {
        expect(getIconFromString('bookmark'), Icons.bookmark);
      });

      test('calendar returns Icons.calendar_today', () {
        expect(getIconFromString('calendar'), Icons.calendar_today);
      });

      test('email returns Icons.email', () {
        expect(getIconFromString('email'), Icons.email);
      });

      test('phone returns Icons.phone', () {
        expect(getIconFromString('phone'), Icons.phone);
      });

      test('lock returns Icons.lock', () {
        expect(getIconFromString('lock'), Icons.lock);
      });

      test('unlock returns Icons.lock_open', () {
        expect(getIconFromString('unlock'), Icons.lock_open);
      });

      test('security returns Icons.security', () {
        expect(getIconFromString('security'), Icons.security);
      });

      test('cloud returns Icons.cloud', () {
        expect(getIconFromString('cloud'), Icons.cloud);
      });

      test('download returns Icons.download', () {
        expect(getIconFromString('download'), Icons.download);
      });

      test('upload returns Icons.upload', () {
        expect(getIconFromString('upload'), Icons.upload);
      });

      test('refresh returns Icons.refresh', () {
        expect(getIconFromString('refresh'), Icons.refresh);
      });

      test('filter returns Icons.filter_list', () {
        expect(getIconFromString('filter'), Icons.filter_list);
      });

      test('sort returns Icons.sort', () {
        expect(getIconFromString('sort'), Icons.sort);
      });

      test('share returns Icons.share', () {
        expect(getIconFromString('share'), Icons.share);
      });

      test('print returns Icons.print', () {
        expect(getIconFromString('print'), Icons.print);
      });
    });

    group('transport icons', () {
      test('car returns Icons.directions_car', () {
        expect(getIconFromString('car'), Icons.directions_car);
      });

      test('plane returns Icons.flight', () {
        expect(getIconFromString('plane'), Icons.flight);
      });

      test('train returns Icons.train', () {
        expect(getIconFromString('train'), Icons.train);
      });

      test('bus returns Icons.directions_bus', () {
        expect(getIconFromString('bus'), Icons.directions_bus);
      });

      test('boat returns Icons.directions_boat', () {
        expect(getIconFromString('boat'), Icons.directions_boat);
      });
    });

    group('view icons', () {
      test('view-list returns Icons.view_list', () {
        expect(getIconFromString('view-list'), Icons.view_list);
      });

      test('view-module returns Icons.view_module', () {
        expect(getIconFromString('view-module'), Icons.view_module);
      });

      test('view-dashboard returns Icons.dashboard', () {
        expect(getIconFromString('view-dashboard'), Icons.dashboard);
      });

      test('view-dashboard-variant returns Icons.dashboard_customize', () {
        expect(getIconFromString('view-dashboard-variant'), Icons.dashboard_customize);
      });
    });

    group('case insensitivity', () {
      test('HOME returns Icons.home', () {
        expect(getIconFromString('HOME'), Icons.home);
      });

      test('Dashboard returns Icons.dashboard', () {
        expect(getIconFromString('Dashboard'), Icons.dashboard);
      });

      test('SETTINGS returns Icons.settings', () {
        expect(getIconFromString('SETTINGS'), Icons.settings);
      });

      test('Search returns Icons.search', () {
        expect(getIconFromString('Search'), Icons.search);
      });
    });

    group('fallback for unknown icons', () {
      test('unknown string returns Icons.help_outline', () {
        expect(getIconFromString('unknown_icon'), Icons.help_outline);
      });

      test('empty string returns Icons.help_outline', () {
        expect(getIconFromString(''), Icons.help_outline);
      });

      test('random gibberish returns Icons.help_outline', () {
        expect(getIconFromString('xyzzy123'), Icons.help_outline);
      });

      test('partial match does not work, returns fallback', () {
        expect(getIconFromString('home_screen'), Icons.help_outline);
      });
    });

    group('financial icons', () {
      test('payment returns Icons.payment', () {
        expect(getIconFromString('payment'), Icons.payment);
      });

      test('credit-card returns Icons.credit_card', () {
        expect(getIconFromString('credit-card'), Icons.credit_card);
      });

      test('money returns Icons.attach_money', () {
        expect(getIconFromString('money'), Icons.attach_money);
      });

      test('bank returns Icons.account_balance', () {
        expect(getIconFromString('bank'), Icons.account_balance);
      });

      test('investment returns Icons.trending_up', () {
        expect(getIconFromString('investment'), Icons.trending_up);
      });
    });

    group('infrastructure icons', () {
      test('database returns Icons.storage', () {
        expect(getIconFromString('database'), Icons.storage);
      });

      test('server returns Icons.dns', () {
        expect(getIconFromString('server'), Icons.dns);
      });

      test('network returns Icons.network_check', () {
        expect(getIconFromString('network'), Icons.network_check);
      });

      test('wifi returns Icons.wifi', () {
        expect(getIconFromString('wifi'), Icons.wifi);
      });

      test('backup returns Icons.backup', () {
        expect(getIconFromString('backup'), Icons.backup);
      });

      test('sync returns Icons.sync', () {
        expect(getIconFromString('sync'), Icons.sync);
      });
    });
  });
}
