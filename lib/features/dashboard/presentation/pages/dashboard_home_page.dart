import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/account/application/account_bloc.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';

/// Home page wrapper for the system dashboard.
///
/// Reads [SystemDashboardCubit] from context (provided by [AppScope]),
/// triggers initial load, and bridges [LifecycleBloc] config into the cubit.
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

      // Trigger account fetch if not loaded yet.
      final accountBloc = context.read<AccountBloc>();
      if (accountBloc.state.status == AccountStatus.initial) {
        accountBloc.add(const AccountFetchEvent());
      }

      // Load the system dashboard.
      context.read<SystemDashboardCubit>().load();

      // Bridge LifecycleBloc app config into the dashboard cubit.
      _bridgeLifecycleConfig();
    });
  }

  void _bridgeLifecycleConfig() {
    try {
      final lifecycleState = context.read<LifecycleBloc>().state;
      _updateAppConfigFromLifecycle(lifecycleState);
    } catch (_) {
      // LifecycleBloc may not be in the widget tree — gracefully ignore.
    }
  }

  void _updateAppConfigFromLifecycle(LifecycleState lifecycleState) {
    final config = lifecycleState.config;

    final environment = ProfileConstants.isProduction
        ? 'prod'
        : ProfileConstants.isDevelopment
        ? 'dev'
        : 'test';

    context.read<SystemDashboardCubit>().updateAppConfig(
      AppConfigSummary(
        currentVersion: AppConstants.appVersion,
        minimumVersion: config?.minimumVersion ?? '-',
        maintenanceMode: config?.maintenanceMode ?? false,
        environment: environment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = BlocBuilder<AccountBloc, AccountState>(
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
    );

    // Wrap with LifecycleBloc listener only when the bloc is available in the tree.
    try {
      context.read<LifecycleBloc>();
      child = BlocListener<LifecycleBloc, LifecycleState>(
        listenWhen: (previous, current) => previous.config != current.config,
        listener: (context, lifecycleState) {
          _updateAppConfigFromLifecycle(lifecycleState);
        },
        child: child,
      );
    } catch (_) {
      // LifecycleBloc not in the widget tree — skip the listener.
    }

    return child;
  }
}
