import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/dashboard_model.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_card.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_responsive_builder.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_skeleton.dart';
import 'package:flutter_bloc_advance/presentation/design_system/theme/semantic_colors.dart';
import 'package:flutter_bloc_advance/presentation/design_system/tokens/app_spacing.dart';
import 'package:flutter_bloc_advance/utils/icon_utils.dart';

import '../../../generated/l10n.dart';
import 'bloc/dashboard_cubit.dart';

/// DashboardPage body widget - displays KPIs, charts, activity, and quick actions.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        switch (state.status) {
          case DashboardStatus.initial:
          case DashboardStatus.loading:
            return const _DashboardSkeleton();
          case DashboardStatus.error:
            return AppErrorState(
              title: S.of(context).failed,
              description: state.message,
              onRetry: () => context.read<DashboardCubit>().load(),
            );
          case DashboardStatus.loaded:
            return _DashboardContent(model: state.model!);
        }
      },
    );
  }
}

/// Main dashboard content when data is loaded.
class _DashboardContent extends StatelessWidget {
  final DashboardModel model;
  const _DashboardContent({required this.model});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardHeader(onRefresh: () => context.read<DashboardCubit>().load()),
          const SizedBox(height: AppSpacing.xl),
          _SummaryCards(summaries: model.summary),
          const SizedBox(height: AppSpacing.xl),
          _ChartSection(summaries: model.summary),
          const SizedBox(height: AppSpacing.xl),
          AppResponsiveBuilder(
            mobile: (_, _) => Column(
              children: [
                _RecentActivitySection(activities: model.activities),
                const SizedBox(height: AppSpacing.xl),
                _QuickActionsSection(actions: model.quickActions),
              ],
            ),
            tablet: (_, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _RecentActivitySection(activities: model.activities)),
                const SizedBox(width: AppSpacing.xl),
                Expanded(child: _QuickActionsSection(actions: model.quickActions)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header with title and refresh button.
class _DashboardHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _DashboardHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.dashboard_outlined, color: colorScheme.primary, size: 28),
        const SizedBox(width: AppSpacing.md),
        Text(S.of(context).dashboard, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        IconButton(tooltip: S.of(context).refresh, icon: const Icon(Icons.refresh), onPressed: onRefresh),
      ],
    );
  }
}

/// Summary stat cards displayed in an adaptive grid.
class _SummaryCards extends StatelessWidget {
  final List<DashboardSummary> summaries;
  const _SummaryCards({required this.summaries});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: summaries.length.clamp(1, 4),
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: summaries.map((s) => _StatCard(summary: s)).toList(),
    );
  }
}

/// Individual stat card showing label, value, and trend.
class _StatCard extends StatelessWidget {
  final DashboardSummary summary;
  const _StatCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;
    final isUp = summary.trend >= 0;
    final trendColor = isUp ? semantic.success : colorScheme.error;
    final trendIcon = isUp ? Icons.trending_up : Icons.trending_down;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconForLabel(summary.label), color: colorScheme.primary, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: trendColor.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, color: trendColor, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${summary.trend.abs()}%',
                      style: textTheme.labelSmall?.copyWith(color: trendColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(_formatValue(summary.value), style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(summary.label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('lead')) return Icons.people_outline;
    if (lower.contains('customer')) return Icons.business;
    if (lower.contains('revenue')) return Icons.attach_money;
    return Icons.analytics_outlined;
  }

  String _formatValue(num value) {
    if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(1);
      return '${formatted}K';
    }
    return value.toString();
  }
}

/// Chart section with a bar chart of summary values.
class _ChartSection extends StatelessWidget {
  final List<DashboardSummary> summaries;
  const _ChartSection({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).chart_kpi_placeholder,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${summaries[groupIndex].label}\n${summaries[groupIndex].value}',
                        textTheme.bodySmall!.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < summaries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              summaries[idx].label,
                              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: summaries.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        color: _barColor(e.key, colorScheme),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _maxY {
    if (summaries.isEmpty) return 100;
    final max = summaries.map((s) => s.value.toDouble()).reduce((a, b) => a > b ? a : b);
    return max * 1.2;
  }

  Color _barColor(int index, ColorScheme cs) {
    final colors = [cs.primary, cs.secondary, cs.tertiary];
    return colors[index % colors.length];
  }
}

/// Recent activity list.
class _RecentActivitySection extends StatelessWidget {
  final List<DashboardActivity> activities;
  const _RecentActivitySection({required this.activities});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(S.of(context).recent_activity, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  S.of(context).subtitle_context,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...activities.map((a) => _ActivityItem(activity: a)),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final DashboardActivity activity;
  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor(colorScheme).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_typeIcon, color: _typeColor(colorScheme), size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(activity.subtitle, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(_formatTime(activity.time), style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  IconData get _typeIcon {
    switch (activity.type) {
      case 'lead':
        return Icons.person_add_outlined;
      case 'sale':
        return Icons.handshake_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _typeColor(ColorScheme cs) {
    switch (activity.type) {
      case 'lead':
        return cs.primary;
      case 'sale':
        return cs.tertiary;
      default:
        return cs.secondary;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }
}

/// Quick actions grid.
class _QuickActionsSection extends StatelessWidget {
  final List<DashboardQuickAction> actions;
  const _QuickActionsSection({required this.actions});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(S.of(context).quick_actions, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions.map((a) => _QuickActionChip(action: a)).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final DashboardQuickAction action;
  const _QuickActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label}')));
      },
      icon: Icon(getIconFromString(action.icon), size: 18),
      label: Text(action.label),
    );
  }
}

/// Skeleton loading state for the dashboard.
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
          Row(
            children: [
              const AppSkeleton(width: 28, height: 28, shape: AppSkeletonShape.circle),
              const SizedBox(width: AppSpacing.md),
              const AppSkeleton.text(width: 160, height: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Stat cards skeleton
          AppAdaptiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: List.generate(3, (_) => const AppSkeleton.card(height: 140)),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Chart skeleton
          const AppSkeleton.card(height: 260),
          const SizedBox(height: AppSpacing.xl),
          // Bottom sections skeleton
          AppResponsiveBuilder(
            mobile: (_, _) => Column(
              children: [
                const AppSkeleton.card(height: 200),
                const SizedBox(height: AppSpacing.xl),
                const AppSkeleton.card(height: 160),
              ],
            ),
            tablet: (_, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: AppSkeleton.card(height: 200)),
                const SizedBox(width: AppSpacing.xl),
                const Expanded(child: AppSkeleton.card(height: 160)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
