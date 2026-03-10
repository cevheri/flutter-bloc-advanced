import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/shell/menu_bloc/menu_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/usecases/load_dashboard_usecase.dart';
import 'package:flutter_bloc_advance/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_page.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final drawerBloc = context.read<MenuBloc>();
      if (drawerBloc.state.menus.isEmpty) {
        final initialLanguage = AppLocalStorageCached.language ?? 'en';
        drawerBloc.add(LoadMenus(language: initialLanguage));
      }

      final accountBloc = context.read<AccountBloc>();
      if (accountBloc.state.status == AccountStatus.initial) {
        accountBloc.add(const AccountFetchEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardCubit(loadDashboardUseCase: LoadDashboardUseCase(context.read<IDashboardRepository>()))..load(),
      child: BlocBuilder<AccountBloc, AccountState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, accountState) {
          if (accountState.status == AccountStatus.success) {
            return const DashboardPage();
          }
          if (accountState.status == AccountStatus.loading || accountState.status == AccountStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
