import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_avatar.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_badge.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_button.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_card.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_divider.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_empty_state.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_error_state.dart';
import 'package:flutter_bloc_advance/presentation/design_system/components/app_skeleton.dart';
import 'package:flutter_bloc_advance/presentation/design_system/tokens/app_spacing.dart';

/// Component catalog screen for dev/test environments.
/// Displays all design system components with their variants and states.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Component Catalog',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Design system components preview',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ..._sections(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context) {
    return [
      _section(context, 'Buttons', _buttonShowcase()),
      _section(context, 'Badges', _badgeShowcase()),
      _section(context, 'Avatars', _avatarShowcase()),
      _section(context, 'Cards', _cardShowcase()),
      _section(context, 'Skeletons', _skeletonShowcase()),
      _section(context, 'Dividers', _dividerShowcase()),
      _section(context, 'Empty & Error States', _stateShowcase()),
    ];
  }

  Widget _section(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.lg),
        content,
        const SizedBox(height: AppSpacing.xxl),
        const Divider(),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buttonShowcase() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        const AppButton(label: 'Filled', variant: AppButtonVariant.filled, onPressed: _noop),
        const AppButton(label: 'Outlined', variant: AppButtonVariant.outlined, onPressed: _noop),
        const AppButton(label: 'Text', variant: AppButtonVariant.text, onPressed: _noop),
        const AppButton(label: 'Ghost', variant: AppButtonVariant.ghost, onPressed: _noop),
        const AppButton(label: 'Destructive', variant: AppButtonVariant.destructive, onPressed: _noop),
        const AppButton(label: 'Loading', variant: AppButtonVariant.filled, isLoading: true, onPressed: _noop),
        const AppButton(icon: Icons.add, variant: AppButtonVariant.icon, onPressed: _noop),
        const AppButton(label: 'With Icon', icon: Icons.download, variant: AppButtonVariant.filled, onPressed: _noop),
        const AppButton(label: 'Small', size: AppComponentSize.sm, onPressed: _noop),
        const AppButton(label: 'Large', size: AppComponentSize.lg, onPressed: _noop),
        const AppButton(label: 'Disabled'),
      ],
    );
  }

  Widget _badgeShowcase() {
    return const Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        AppBadge(label: 'Default'),
        AppBadge(label: 'Secondary', variant: AppBadgeVariant.secondary),
        AppBadge(label: 'Destructive', variant: AppBadgeVariant.destructive),
        AppBadge(label: 'Outline', variant: AppBadgeVariant.outline),
        AppBadge(label: 'Success', variant: AppBadgeVariant.success),
        AppBadge(label: 'Warning', variant: AppBadgeVariant.warning),
        AppBadge(label: 'With Icon', icon: Icons.star, variant: AppBadgeVariant.filled),
      ],
    );
  }

  Widget _avatarShowcase() {
    return const Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppAvatar(initials: 'SM', size: AppComponentSize.sm),
        AppAvatar(initials: 'MD'),
        AppAvatar(initials: 'LG', size: AppComponentSize.lg),
        AppAvatar(initials: 'ON', status: AppAvatarStatus.online),
        AppAvatar(initials: 'AW', status: AppAvatarStatus.away),
        AppAvatar(initials: 'OF', status: AppAvatarStatus.offline),
      ],
    );
  }

  Widget _cardShowcase() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppCard(
                variant: AppCardVariant.elevated,
                header: const Text('Elevated Card'),
                child: const Text('Content goes here with shadow elevation.'),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppCard(
                variant: AppCardVariant.outlined,
                header: const Text('Outlined Card'),
                child: const Text('Content goes here with border outline.'),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppCard(
                variant: AppCardVariant.filled,
                header: const Text('Filled Card'),
                child: const Text('Content goes here with filled background.'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          variant: AppCardVariant.outlined,
          onTap: _noop,
          header: const Text('Clickable Card'),
          footer: const Text('Footer area'),
          child: const Text('This card has hover effects and is clickable.'),
        ),
      ],
    );
  }

  Widget _skeletonShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton.text(width: 200),
        const SizedBox(height: AppSpacing.md),
        const AppSkeleton.text(width: 300),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            AppSkeleton.circle(diameter: 40),
            SizedBox(width: AppSpacing.md),
            Expanded(child: AppSkeleton.text()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const AppSkeleton.card(height: 100),
        const SizedBox(height: AppSpacing.md),
        AppSkeleton.listTile(),
      ],
    );
  }

  Widget _dividerShowcase() {
    return const Column(
      children: [
        AppDivider(),
        SizedBox(height: AppSpacing.md),
        AppDivider(label: 'OR'),
        SizedBox(height: AppSpacing.md),
        AppDivider(label: 'Section'),
      ],
    );
  }

  Widget _stateShowcase() {
    return Column(
      children: [
        const AppEmptyState(
          title: 'No items found',
          description: 'Try adjusting your filters or create a new item.',
          actionLabel: 'Create Item',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppErrorState(title: 'Failed to load', description: 'Something went wrong. Please try again.', onRetry: _noop),
      ],
    );
  }

  static void _noop() {}
}
