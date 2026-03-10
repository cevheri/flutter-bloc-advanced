import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_breakpoints.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_data_table.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_mobile_card_list.dart';

/// A high-level responsive list view that automatically switches between
/// a desktop [AppDataTable] and a mobile [AppMobileCardList] based on screen width.
///
/// Desktop (>= 768px): scrollable layout with title, search widget, and data table.
/// Mobile (< 768px): column layout with title, search widget, and card list.
///
/// ```dart
/// AppResponsiveListView<UserEntity>(
///   title: 'Users',
///   items: users,
///   columns: [
///     AppTableColumn(label: 'Name', flex: 3, builder: (ctx, u) => Text(u.name)),
///   ],
///   mobileCardBuilder: (ctx, u) => UserCard(user: u),
///   onCreateNew: () => navigateToCreate(),
/// )
/// ```
class AppResponsiveListView<T> extends StatelessWidget {
  const AppResponsiveListView({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.isLoading = false,
    this.onCreateNew,
    this.createNewKey,
    this.createLabel,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyText,
    required this.columns,
    this.desktopSearchWidget,
    this.onPrevious,
    this.onNext,
    this.showCheckbox = false,
    required this.mobileCardBuilder,
    this.mobileSearchWidget,
  });

  // Common
  final String title;
  final String? subtitle;
  final List<T>? items;
  final bool isLoading;
  final VoidCallback? onCreateNew;
  final Key? createNewKey;
  final String? createLabel;
  final IconData emptyIcon;
  final String? emptyText;

  // Desktop
  final List<AppTableColumn<T>> columns;
  final Widget? desktopSearchWidget;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showCheckbox;

  // Mobile
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final Widget? mobileSearchWidget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppBreakpoints.isMobile(constraints.maxWidth)) {
          return _buildMobileView(context);
        }
        return _buildDesktopView(context);
      },
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                if (onCreateNew != null)
                  FilledButton.icon(
                    key: createNewKey,
                    onPressed: onCreateNew,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(createLabel ?? 'New'),
                  ),
              ],
            ),
            if (desktopSearchWidget != null) ...[
              const SizedBox(height: 20),
              desktopSearchWidget!,
            ],
            const SizedBox(height: 16),
            AppDataTable<T>(
              columns: columns,
              items: items ?? [],
              showCheckbox: showCheckbox,
              onPrevious: onPrevious,
              onNext: onNext,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text(title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
              if (onCreateNew != null)
                FilledButton.icon(
                  key: createNewKey,
                  onPressed: onCreateNew,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(createLabel ?? 'New'),
                ),
            ],
          ),
        ),
        if (mobileSearchWidget != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: mobileSearchWidget!,
          ),
        Expanded(
          child: AppMobileCardList<T>(
            items: items,
            cardBuilder: mobileCardBuilder,
            isLoading: isLoading,
            emptyIcon: emptyIcon,
            emptyText: emptyText,
          ),
        ),
      ],
    );
  }
}
