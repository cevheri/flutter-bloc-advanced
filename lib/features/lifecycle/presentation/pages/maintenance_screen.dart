import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_bloc.dart';
import 'package:flutter_bloc_advance/features/lifecycle/application/lifecycle_event.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';

/// Full-screen maintenance mode overlay.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, this.message, this.estimatedEnd});

  final String? message;
  final String? estimatedEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 80, color: colorScheme.tertiary),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Under Maintenance',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message ?? 'We are performing scheduled maintenance. Please check back soon.',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (estimatedEnd != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Estimated return: $estimatedEnd',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Retry',
                icon: Icons.refresh,
                variant: AppButtonVariant.outlined,
                onPressed: () => context.read<LifecycleBloc>().add(const LifecycleCheckEvent()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
