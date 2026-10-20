import 'package:flutter_bloc_advance/features/dashboard/navigation/dashboard_routes.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard feature keeps home route ownership', () {
    expect(DashboardFeatureRoutes.routes, hasLength(1));
    expect(DashboardFeatureRoutes.routes.single.name, 'home');
    expect(DashboardFeatureRoutes.routes.single.path, ApplicationRoutesConstants.home);
  });
}
