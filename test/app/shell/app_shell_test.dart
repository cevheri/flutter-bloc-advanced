@Tags(['widget'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_bloc_advance/app/connectivity/connectivity_banner.dart';
import 'package:flutter_bloc_advance/app/shell/top_bar/top_bar_widget.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_env.dart';

void main() {
  // The connectivity service is a singleton, so this file keeps the device offline for all of its tests.
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => call.method == 'check' ? ['none'] : null,
    );
    await ConnectivityService.instance.initialize();
    expect(ConnectivityService.instance.currentStatus, ConnectivityStatus.offline);
  });

  testWidgets('offline, the phone top bar starts right below the banner, with no status bar gap between them', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    // An Android phone with a 48 px status bar, as on an API 36 emulator.
    tester.view.padding = const FakeViewPadding(top: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 48);
    TestEnv.authenticate();

    await tester.pumpWidget(const App(language: 'en'));
    await tester.pumpAndSettle();

    final banner = tester.getRect(find.byType(ConnectivityBanner));
    expect(banner.top, 0);
    expect(banner.bottom, greaterThan(48), reason: 'the banner itself pads for the status bar');
    expect(tester.getRect(find.byType(TopBarWidget)).top, banner.bottom);
  });
}
