import 'package:flutter_bloc_advance/features/settings/navigation/settings_routes.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings feature exposes expected route', () {
    expect(SettingsFeatureRoutes.routes, hasLength(1));
    expect(SettingsFeatureRoutes.routes.single.path, ApplicationRoutesConstants.settings);
    expect(SettingsFeatureRoutes.routes.single.name, 'settings');
  });
}
