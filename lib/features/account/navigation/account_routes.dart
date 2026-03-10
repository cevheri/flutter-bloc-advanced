import 'package:flutter_bloc_advance/features/account/presentation/pages/account_page.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_page_transition.dart';
import 'package:go_router/go_router.dart';

class AccountFeatureRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      path: '/account',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: const AccountPage(),
      ),
    ),
  ];
}
