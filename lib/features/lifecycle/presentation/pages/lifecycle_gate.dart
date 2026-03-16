import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/force_update_screen.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/maintenance_screen.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';

/// Wraps the app content and gates it behind lifecycle checks.
///
/// Shows [ForceUpdateScreen] or [MaintenanceScreen] when appropriate,
/// otherwise passes through to [child].
class LifecycleGate extends StatelessWidget {
  const LifecycleGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LifecycleBloc, LifecycleState>(
      builder: (context, state) {
        switch (state.status) {
          case LifecycleStatus.forceUpdate:
            return ForceUpdateScreen(
              storeUrl: state.config?.storeUrl,
              currentVersion: AppConstants.appVersion,
              minimumVersion: state.config?.minimumVersion,
            );
          case LifecycleStatus.maintenance:
            return MaintenanceScreen(
              message: state.config?.maintenanceMessage,
              estimatedEnd: state.config?.maintenanceEstimatedEnd,
            );
          case LifecycleStatus.initial:
          case LifecycleStatus.loading:
          case LifecycleStatus.ready:
          case LifecycleStatus.failure:
            return child;
        }
      },
    );
  }
}
