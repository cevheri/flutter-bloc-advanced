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
      builder: (context, state) => switch (state) {
        LifecycleForceUpdate(:final config) => ForceUpdateScreen(
          storeUrl: config.storeUrl,
          currentVersion: AppConstants.appVersion,
          minimumVersion: config.minimumVersion,
        ),
        LifecycleMaintenance(:final config) => MaintenanceScreen(
          message: config.maintenanceMessage,
          estimatedEnd: config.maintenanceEstimatedEnd,
        ),
        LifecycleInitial() || LifecycleLoading() || LifecycleReady() => child,
      },
    );
  }
}
