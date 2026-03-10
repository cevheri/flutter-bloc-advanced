import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_home_page.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:go_router/go_router.dart';

class DashboardFeatureRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      name: 'home',
      path: ApplicationRoutesConstants.home,
      pageBuilder: (context, state) =>
          appTransitionPage(state: state, type: AppPageTransitionType.fade, child: const DashboardHomePage()),
    ),
  ];
}
