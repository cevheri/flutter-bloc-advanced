import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/utils/icon_utils.dart';

import 'bloc/dashboard_cubit.dart';
import '../../../data/models/dashboard_model.dart';

/// DashboardPage body widget
///
/// This widget will be used as the body of `HomeScreen` in local/dev runs.
/// It does not contain an AppBar or Drawer; those are provided by `HomeScreen`.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DashboardHeader(),
              const SizedBox(height: 16),
              _SummaryCardsRow(isWide: isWide),
              const SizedBox(height: 16),
              const _KpiPlaceholder(),
              const SizedBox(height: 16),
              _TwoColumns(left: const _RecentActivityList(), right: const _QuickActionsGrid(), isWide: isWide),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.dashboard_outlined, color: color.primary),
          const SizedBox(width: 12),
          Text('Dashboard', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
    );
  }
}

class _SummaryCardsRow extends StatelessWidget {
  final bool isWide;
  const _SummaryCardsRow({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final children = [
      const _SummaryCard(label: 'Leads', value: '120', trend: 8),
      const _SummaryCard(label: 'Customers', value: '54', trend: -2),
      const _SummaryCard(label: 'Revenue', value: '₺12.500', trend: 12),
    ];
    if (isWide) {
      return Row(
        children: [
          for (final child in children) ...[Expanded(child: child), const SizedBox(width: 12)],
        ]..removeLast(),
      );
    }
    return Column(
      children: [
        for (final child in children) ...[child, const SizedBox(height: 12)],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final int trend;
  const _SummaryCard({required this.label, required this.value, required this.trend});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUp = trend >= 0;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;
    final trendColor = isUp ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: color.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Row(
            children: [
              Icon(icon, color: trendColor, size: 16),
              const SizedBox(width: 4),
              Text('${trend.abs()}%', style: textTheme.labelMedium?.copyWith(color: trendColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiPlaceholder extends StatelessWidget {
  const _KpiPlaceholder();
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outlineVariant),
      ),
      child: const Center(child: Text('Chart / KPI Placeholder')),
    );
  }
}

class _TwoColumns extends StatelessWidget {
  final Widget left;
  final Widget right;
  final bool isWide;
  const _TwoColumns({required this.left, required this.right, required this.isWide});

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(children: [left, const SizedBox(height: 16), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(4, (i) => _ActivityTile(index: i)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final int index;
  const _ActivityTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(backgroundColor: color.secondaryContainer, child: Text('${index + 1}')),
      title: const Text('Sample activity item'),
      subtitle: const Text('Subtitle / Context'),
      trailing: const Text('just now'),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = context.watch<DashboardCubit>().state;

    final List<DashboardQuickAction> actions = state.status == DashboardStatus.loaded
        ? state.model!.quickActions
        : const [
            DashboardQuickAction(id: 'qa1', label: 'New Lead', icon: 'person_add'),
            DashboardQuickAction(id: 'qa2', label: 'Add Task', icon: 'task'),
            DashboardQuickAction(id: 'qa3', label: 'New Deal', icon: 'wallet'),
            DashboardQuickAction(id: 'qa4', label: 'Send Email', icon: 'email'),
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions.take(6).map((a) => _ActionButton(action: a)).toList()),
          if (actions.length > 6) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAllActions(context, actions),
                icon: const Icon(Icons.more_horiz),
                label: const Text('More'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllActions(BuildContext context, List<DashboardQuickAction> actions) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            itemCount: actions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = actions[i];
              return ListTile(
                leading: Icon(getIconFromString(a.icon)),
                title: Text(a.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _onActionTap(context, a);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _onActionTap(BuildContext context, DashboardQuickAction action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label}')));
  }
}

class _ActionButton extends StatelessWidget {
  final DashboardQuickAction action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => _onTap(context),
      icon: Icon(getIconFromString(action.icon)),
      label: Text(action.label),
    );
  }

  void _onTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: ${action.label}')));
  }
}
