import 'package:flutter/material.dart';

/// A mobile-optimized card list that handles loading, empty, and populated states.
///
/// Renders a scrollable [ListView.separated] of cards built by [cardBuilder],
/// with a footer showing the item count.
///
/// ```dart
/// AppMobileCardList<UserEntity>(
///   items: users,
///   cardBuilder: (context, user) => UserCard(user: user),
///   emptyIcon: Icons.people_outline,
///   emptyText: 'No users found',
/// )
/// ```
class AppMobileCardList<T> extends StatelessWidget {
  const AppMobileCardList({
    super.key,
    required this.items,
    required this.cardBuilder,
    this.isLoading = false,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyText,
  });

  final List<T>? items;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final bool isLoading;
  final IconData emptyIcon;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items != null && items!.isNotEmpty) {
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => cardBuilder(context, items![index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${items!.length} row(s) listed.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(emptyIcon, size: 48, color: cs.onSurfaceVariant.withAlpha(102)),
          if (emptyText != null) ...[
            const SizedBox(height: 12),
            Text(emptyText!, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
