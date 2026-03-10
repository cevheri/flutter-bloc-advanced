import 'package:flutter/material.dart';

/// Column definition for [AppDataTable].
class AppTableColumn<T> {
  const AppTableColumn({
    required this.label,
    required this.flex,
    required this.builder,
    this.alignment = TextAlign.left,
  });

  final String label;
  final int flex;
  final Widget Function(BuildContext context, T item) builder;
  final TextAlign alignment;
}

/// A generic, reusable data table with header, hover-enabled rows, and a pagination footer.
///
/// Use with [AppTableColumn] to define columns declaratively:
/// ```dart
/// AppDataTable<UserEntity>(
///   columns: [
///     AppTableColumn(label: 'Name', flex: 3, builder: (ctx, u) => Text(u.name)),
///     AppTableColumn(label: 'Email', flex: 4, builder: (ctx, u) => Text(u.email)),
///   ],
///   items: users,
/// )
/// ```
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.showCheckbox = false,
    this.onPrevious,
    this.onNext,
  });

  final List<AppTableColumn<T>> columns;
  final List<T> items;
  final bool showCheckbox;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          _AppTableHeader<T>(columns: columns, showCheckbox: showCheckbox),
          for (int i = 0; i < items.length; i++)
            _AppTableRow<T>(
              columns: columns,
              item: items[i],
              isLast: i == items.length - 1,
              showCheckbox: showCheckbox,
            ),
          _AppTableFooter(itemCount: items.length, onPrevious: onPrevious, onNext: onNext),
        ],
      ),
    );
  }
}

class _AppTableHeader<T> extends StatelessWidget {
  const _AppTableHeader({required this.columns, required this.showCheckbox});

  final List<AppTableColumn<T>> columns;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showCheckbox) const SizedBox(width: 28, child: Checkbox(value: false, onChanged: null)),
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(col.label, textAlign: col.alignment, style: style, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppTableRow<T> extends StatefulWidget {
  const _AppTableRow({required this.columns, required this.item, required this.isLast, required this.showCheckbox});

  final List<AppTableColumn<T>> columns;
  final T item;
  final bool isLast;
  final bool showCheckbox;

  @override
  State<_AppTableRow<T>> createState() => _AppTableRowState<T>();
}

class _AppTableRowState<T> extends State<_AppTableRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _hovered ? cs.onSurface.withAlpha(13) : Colors.transparent,
          border: widget.isLast ? null : Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (widget.showCheckbox) const SizedBox(width: 28, child: Checkbox(value: false, onChanged: null)),
            for (final col in widget.columns)
              Expanded(
                flex: col.flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Align(
                    alignment: col.alignment == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft,
                    child: col.builder(context, widget.item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTableFooter extends StatelessWidget {
  const _AppTableFooter({required this.itemCount, this.onPrevious, this.onNext});

  final int itemCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$itemCount row(s) listed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          OutlinedButton(onPressed: onPrevious, child: const Text('Previous')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}
