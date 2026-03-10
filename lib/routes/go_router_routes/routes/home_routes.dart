import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/dashboard_repository.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/drawer/drawer_bloc/drawer_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/language_notifier.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_page_transition.dart';
import 'package:flutter_bloc_advance/presentation/screen/dashboard/bloc/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/presentation/screen/dashboard/dashboard_page.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:go_router/go_router.dart';

class HomeRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      name: 'home',
      path: ApplicationRoutesConstants.home,
      pageBuilder: (context, state) {
        // Ensure menus are loaded
        final drawerBloc = context.read<DrawerBloc>();
        if (drawerBloc.state.menus.isEmpty) {
          final initialLanguage = AppLocalStorageCached.language ?? 'en';
          drawerBloc.add(LoadMenus(language: initialLanguage));
        }

        return appTransitionPage(
          state: state,
          type: AppPageTransitionType.fade,
          child: BlocProvider(
            create: (context) => AccountBloc(repository: AccountRepository())..add(const AccountFetchEvent()),
            child: BlocBuilder<AccountBloc, AccountState>(
              buildWhen: (previous, current) => current.status != previous.status,
              builder: (context, accountState) {
                if (accountState.status == AccountStatus.success) {
                  return ValueListenableBuilder<String>(
                    valueListenable: LanguageNotifier.current,
                    builder: (context, lang, _) {
                      return Localizations.override(
                        context: context,
                        locale: Locale(lang),
                        child: BlocProvider(
                          create: (context) => DashboardCubit(repository: DashboardMockRepository())..load(),
                          child: const DashboardPage(),
                        ),
                      );
                    },
                  );
                }
                if (accountState.status == AccountStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    ),
  ];
}
