import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/dashboard/application/dashboard_cubit.dart';
import 'package:flutter_bloc_advance/infrastructure/connectivity/connectivity_service.dart';
import 'package:flutter_bloc_advance/infrastructure/http/circuit_breaker.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_card.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_responsive_builder.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_skeleton.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:go_router/go_router.dart';

/// System Dashboard page — displays infrastructure metrics, circuit breaker
/// health, feature flags, interceptor chain, and quick actions.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemDashboardCubit, SystemDashboardState>(
      builder: (context, state) {
        switch (state.status) {
          case SystemDashboardStatus.initial:
          case SystemDashboardStatus.loading:
            return const _DashboardSkeleton();
          case SystemDashboardStatus.error:
            return AppErrorState(
              title: 'Dashboard Error',
              description: state.errorMessage,
              onRetry: () => context.read<SystemDashboardCubit>().load(),
            );
          case SystemDashboardStatus.loaded:
            return _DashboardContent(state: state);
        }
      },
    );
  }
}

// =============================================================================
// Main content
// =============================================================================

class _DashboardContent extends StatelessWidget {
  final SystemDashboardState state;
  const _DashboardContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardHeader(onRefresh: () => context.read<SystemDashboardCubit>().load()),
          const SizedBox(height: AppSpacing.xl),
          _KpiCards(state: state),
          const SizedBox(height: AppSpacing.xl),
          _CircuitBreakerHealthSection(endpoints: state.endpointHealthList),
          const SizedBox(height: AppSpacing.xl),
          AppResponsiveBuilder(
            mobile: (_, _) => Column(
              children: [
                _FeatureFlagsSection(flags: state.featureFlags),
                const SizedBox(height: AppSpacing.xl),
                _AppConfigSection(config: state.appConfig),
              ],
            ),
            tablet: (_, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _FeatureFlagsSection(flags: state.featureFlags)),
                const SizedBox(width: AppSpacing.xl),
                Expanded(child: _AppConfigSection(config: state.appConfig)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _InterceptorChainSection(interceptors: state.interceptors),
          const SizedBox(height: AppSpacing.xl),
          const _QuickActionsSection(),
        ],
      ),
    );
  }
}

// =============================================================================
// 1. Header
// =============================================================================

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DashboardHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.admin_panel_settings_outlined, color: colorScheme.primary, size: 28),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            'System Dashboard',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Text(
            'v${AppConstants.appVersion}',
            style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimaryContainer),
          ),
        ),
        const Spacer(),
        IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: onRefresh),
      ],
    );
  }
}

// =============================================================================
// 2. KPI Cards
// =============================================================================

class _KpiCards extends StatelessWidget {
  final SystemDashboardState state;
  const _KpiCards({required this.state});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: [
        _KpiCard(
          icon: Icons.wifi,
          label: 'Connectivity',
          value: state.connectivity == ConnectivityStatus.online ? 'Online' : 'Offline',
          dotColor: state.connectivity == ConnectivityStatus.online
              ? context.semanticColors.success
              : Theme.of(context).colorScheme.error,
        ),
        _KpiCard(
          icon: Icons.shield_outlined,
          label: 'Circuit Breaker',
          value: '${state.circuitBreakerTotal} endpoints',
          subtitle: '${state.circuitBreakerOpen} open',
        ),
        _KpiCard(icon: Icons.storage_outlined, label: 'Cache', value: '${state.cacheItemCount} items cached'),
        _KpiCard(
          icon: Icons.flag_outlined,
          label: 'Feature Flags',
          value: '${state.featureFlagsOn}/${state.featureFlagsTotal} enabled',
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? dotColor;

  const _KpiCard({required this.icon, required this.label, required this.value, this.subtitle, this.dotColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(value, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 3. Circuit Breaker Health
// =============================================================================

class _CircuitBreakerHealthSection extends StatelessWidget {
  final List<EndpointHealth> endpoints;
  const _CircuitBreakerHealthSection({required this.endpoints});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('Circuit Breaker Health', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (endpoints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No endpoints tracked yet',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...endpoints.map((ep) => _EndpointHealthRow(endpoint: ep)),
        ],
      ),
    );
  }
}

class _EndpointHealthRow extends StatelessWidget {
  final EndpointHealth endpoint;
  const _EndpointHealthRow({required this.endpoint});

  Color _stateColor(BuildContext context) {
    switch (endpoint.state) {
      case CircuitBreakerState.closed:
        return context.semanticColors.success;
      case CircuitBreakerState.halfOpen:
        return Colors.orange;
      case CircuitBreakerState.open:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = _stateColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Text(endpoint.endpoint, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              endpoint.state.name,
              style: textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'Failures: ${endpoint.failureCount}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4a. Feature Flags
// =============================================================================

class _FeatureFlagsSection extends StatelessWidget {
  final Map<String, bool> flags;
  const _FeatureFlagsSection({required this.flags});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('Feature Flags', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (flags.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No feature flags configured',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...flags.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key, style: textTheme.bodyMedium)),
                    Switch(
                      value: entry.value,
                      onChanged: (value) {
                        context.read<SystemDashboardCubit>().toggleFeatureFlag(entry.key, value);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4b. App Config
// =============================================================================

class _AppConfigSection extends StatelessWidget {
  final AppConfigSummary config;
  const _AppConfigSection({required this.config});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_applications_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('App Configuration', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ConfigRow(label: 'Current Version', value: config.currentVersion),
          _ConfigRow(label: 'Minimum Version', value: config.minimumVersion),
          _ConfigRow(
            label: 'Maintenance Mode',
            value: config.maintenanceMode ? 'ON' : 'OFF',
            valueColor: config.maintenanceMode ? Theme.of(context).colorScheme.error : null,
          ),
          _ConfigRow(label: 'Environment', value: config.environment),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _ConfigRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. Interceptor Chain
// =============================================================================

class _InterceptorChainSection extends StatelessWidget {
  final List<InterceptorInfo> interceptors;
  const _InterceptorChainSection({required this.interceptors});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('Interceptor Chain', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...interceptors.map((info) => _InterceptorRow(info: info)),
        ],
      ),
    );
  }
}

class _InterceptorRow extends StatelessWidget {
  final InterceptorInfo info;
  const _InterceptorRow({required this.info});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = info.active ? context.semanticColors.success : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${info.order}', style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(info.name, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(info.detail, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 6. Quick Actions
// =============================================================================

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text('Quick Actions', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.read<SystemDashboardCubit>().clearCache(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Clear Cache'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => context.read<SystemDashboardCubit>().resetCircuitBreakers(),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reset Circuit Breakers'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => GoRouter.of(context).go('/dynamic-forms/sample'),
                icon: const Icon(Icons.dynamic_form_outlined, size: 18),
                label: const Text('Open Dynamic Forms'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Skeleton loading state
// =============================================================================

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header skeleton
          const Row(
            children: [
              AppSkeleton(width: 28, height: 28, shape: AppSkeletonShape.circle),
              SizedBox(width: AppSpacing.md),
              AppSkeleton.text(width: 200, height: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // KPI cards skeleton
          AppAdaptiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 4,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: List.generate(4, (_) => const AppSkeleton.card(height: 100)),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Circuit breaker section skeleton
          const AppSkeleton.card(height: 180),
          const SizedBox(height: AppSpacing.xl),
          // Middle sections skeleton
          AppResponsiveBuilder(
            mobile: (_, _) => const Column(
              children: [
                AppSkeleton.card(height: 200),
                SizedBox(height: AppSpacing.xl),
                AppSkeleton.card(height: 160),
              ],
            ),
            tablet: (_, _) => const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AppSkeleton.card(height: 200)),
                SizedBox(width: AppSpacing.xl),
                Expanded(child: AppSkeleton.card(height: 160)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Interceptor chain skeleton
          const AppSkeleton.card(height: 240),
          const SizedBox(height: AppSpacing.xl),
          // Quick actions skeleton
          const AppSkeleton.card(height: 80),
        ],
      ),
    );
  }
}
