import 'package:flutter/material.dart';

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
              _DashboardHeader(),
              const SizedBox(height: 16),
              _SummaryCardsRow(isWide: isWide),
              const SizedBox(height: 16),
              _KpiPlaceholder(),
              const SizedBox(height: 16),
              _TwoColumns(left: _RecentActivityList(), right: _QuickActionsGrid(), isWide: isWide),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
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
      _SummaryCard(label: 'Leads', value: '120', trend: 8),
      _SummaryCard(label: 'Customers', value: '54', trend: -2),
      _SummaryCard(label: 'Revenue', value: '₺12.500', trend: 12),
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
            backgroundColor: color.primary.withOpacity(0.12),
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
          Text('Quick Actions', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _QuickActionTile(icon: Icons.person_add, label: 'New Lead'),
              _QuickActionTile(icon: Icons.task_alt, label: 'Add Task'),
              _QuickActionTile(icon: Icons.wallet, label: 'New Deal'),
              _QuickActionTile(icon: Icons.email, label: 'Send Email'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickActionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(color: color.secondaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color.onSecondaryContainer),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
