import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/features/catalog/presentation/pages/catalog_screen.dart';
import 'package:go_router/go_router.dart';

class CatalogFeatureRoutes {
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
