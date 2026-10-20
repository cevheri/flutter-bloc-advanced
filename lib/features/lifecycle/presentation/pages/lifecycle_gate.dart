import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_state.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/force_update_screen.dart';
import 'package:flutter_bloc_advance/features/lifecycle/presentation/pages/maintenance_screen.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';

/// Wraps the app content and gates it behind lifecycle checks.
///
/// Shows [ForceUpdateScreen] or [MaintenanceScreen] when appropriate,
/// otherwise passes through to [child]. `App` places it in the `MaterialApp` builder, so the screens replace the
/// router and have no Navigator above them.
///
/// It asks [LifecycleBloc] for a check each time the app comes back to the foreground; the bloc decides whether the
/// last check is recent enough.
class LifecycleGate extends StatefulWidget {
  const LifecycleGate({super.key, required this.child});

  final Widget child;

  @override
  State<LifecycleGate> createState() => _LifecycleGateState();
}

class _LifecycleGateState extends State<LifecycleGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<LifecycleBloc>().add(const LifecycleCheckEvent(trigger: LifecycleCheckTrigger.resume));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LifecycleBloc, LifecycleState>(
      builder: (context, state) => switch (state) {
        LifecycleForceUpdate(:final config) => ForceUpdateScreen(
          storeUrl: config.storeUrl,
          currentVersion: AppConstants.appVersion,
          minimumVersion: config.minimumVersion,
        ),
        LifecycleMaintenance(:final config, :final checking) => MaintenanceScreen(
          message: config.maintenanceMessage,
          estimatedEnd: config.maintenanceEstimatedEnd,
          checking: checking,
        ),
        LifecycleInitial() || LifecycleLoading() || LifecycleReady() => widget.child,
      },
    );
  }
}
