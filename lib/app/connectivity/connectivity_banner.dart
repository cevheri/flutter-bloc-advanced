import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/app/connectivity/connectivity_cubit.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_durations.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';

/// An animated banner that appears at the top of the scaffold when the device is offline.
///
/// Uses [BlocBuilder] to listen to [ConnectivityCubit] and slides in/out
/// with an animation. Styled with the app's design system tokens.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        return AnimatedSlide(
          offset: state.isOffline ? Offset.zero : const Offset(0, -1),
          duration: AppDurations.normal,
          curve: AppDurations.easeInOut,
          child: AnimatedOpacity(
            opacity: state.isOffline ? 1.0 : 0.0,
            duration: AppDurations.normal,
            child: state.isOffline ? _OfflineBannerContent() : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: colorScheme.error),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, color: colorScheme.onError, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'No internet connection',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: colorScheme.onError, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
