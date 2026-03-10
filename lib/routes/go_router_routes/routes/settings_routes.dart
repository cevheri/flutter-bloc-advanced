import 'package:flutter_bloc_advance/presentation/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/presentation/screen/settings/settings_screen.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:go_router/go_router.dart';

class SettingsRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      name: 'settings',
      path: ApplicationRoutesConstants.settings,
      pageBuilder: (context, state) =>
          appTransitionPage(state: state, type: AppPageTransitionType.fade, child: const SettingsScreen()),
    ),
  ];
}
