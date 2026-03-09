import 'package:flutter_bloc_advance/presentation/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/presentation/screen/account/account_screen.dart';
import 'package:go_router/go_router.dart';

class AccountRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      path: '/account',
      pageBuilder: (context, state) => appTransitionPage(
        state: state,
        type: AppPageTransitionType.slideRight,
        child: AccountScreen(returnToSettings: state.uri.queryParameters['returnToSettings'] == 'true'),
      ),
    ),
  ];
}
