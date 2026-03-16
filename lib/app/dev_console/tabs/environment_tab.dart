import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/infrastructure/config/environment.dart';
import 'package:flutter_bloc_advance/shared/utils/app_constants.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_radius.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';
import 'package:go_router/go_router.dart';

class EnvironmentTab extends StatelessWidget {
  const EnvironmentTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    final envInfo = _buildEnvironmentInfo();
    final routeConfig = GoRouter.of(context).configuration;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader(title: 'Environment', icon: Icons.settings_applications_outlined),
        const SizedBox(height: AppSpacing.sm),
        ...envInfo.entries.map(
          (entry) => _InfoRow(label: entry.key, value: entry.value, colorScheme: colorScheme, textTheme: textTheme),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(title: 'Route Tree', icon: Icons.account_tree_outlined),
        const SizedBox(height: AppSpacing.sm),
        _buildRouteTree(context, routeConfig.routes, 0, colorScheme, textTheme, semantic),
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(title: 'Current Route', icon: Icons.location_on_outlined),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(
          label: 'Path',
          value: GoRouterState.of(context).uri.toString(),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Map<String, String> _buildEnvironmentInfo() {
    return {
      'Environment': ProfileConstants.isProduction ? 'Production' : (ProfileConstants.isTest ? 'Test' : 'Development'),
      'API Endpoint': ProfileConstants.isProduction ? (ProfileConstants.api?.toString() ?? 'N/A') : 'Mock',
      'App Version': AppConstants.appVersion.isNotEmpty ? AppConstants.appVersion : 'N/A',
      'Build Number': AppConstants.appBuildNumber.isNotEmpty ? AppConstants.appBuildNumber : 'N/A',
      'App Name': AppConstants.appName.isNotEmpty ? AppConstants.appName : 'N/A',
    };
  }

  Widget _buildRouteTree(
    BuildContext context,
    List<RouteBase> routes,
    int depth,
    ColorScheme colorScheme,
    TextTheme textTheme,
    SemanticColors semantic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: routes.map((route) {
        if (route is GoRoute) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: depth * AppSpacing.lg),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route, size: 14, color: semantic.info),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        route.path,
                        style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                      ),
                      if (route.name != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '(${route.name})',
                          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (route.routes.isNotEmpty)
                _buildRouteTree(context, route.routes, depth + 1, colorScheme, textTheme, semantic),
            ],
          );
        } else if (route is ShellRoute) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: depth * AppSpacing.lg),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(40),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers, size: 14, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('ShellRoute', style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              _buildRouteTree(context, route.routes, depth + 1, colorScheme, textTheme, semantic),
            ],
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.colorScheme, required this.textTheme});

  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
