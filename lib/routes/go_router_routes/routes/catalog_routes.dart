import 'package:flutter_bloc_advance/configuration/environment.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/presentation/screen/catalog/catalog_screen.dart';
import 'package:go_router/go_router.dart';

class CatalogRoutes {
  static final List<GoRoute> routes = [
    if (!ProfileConstants.isProduction)
      GoRoute(
        name: 'catalog',
        path: '/catalog',
        pageBuilder: (context, state) =>
            appTransitionPage(state: state, type: AppPageTransitionType.fade, child: const CatalogScreen()),
      ),
  ];
}
