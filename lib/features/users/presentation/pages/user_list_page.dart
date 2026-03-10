import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/authorities_dropdown.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/components/app_status_badge.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_data_table.dart';
import 'package:flutter_bloc_advance/shared/widgets/app_responsive_list_view.dart';
import 'package:flutter_bloc_advance/app/router/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

UserSearchEvent _buildSearchEventFromForm(FormBuilderState? formState) {
  final pageText = formState?.fields['rangeStart']?.value?.toString() ?? '0';
  final sizeText = formState?.fields['rangeEnd']?.value?.toString() ?? '100';
  final authorityText = formState?.fields['authorities']?.value?.toString();
  final nameText = formState?.fields['name']?.value?.toString();

  String? normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  return UserSearchEvent(
    page: int.tryParse(pageText) ?? 0,
    size: int.tryParse(sizeText) ?? 100,
    authorities: normalize(authorityText),
    name: normalize(nameText),
  );
}

class ListUserScreen extends StatefulWidget {
  const ListUserScreen({super.key});

  @override
  State<ListUserScreen> createState() => _ListUserScreenState();
}

class _ListUserScreenState extends State<ListUserScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _handleUserStateChanges,
      child: UserListView(formKey: _formKey),
    );
  }

  void _handleUserStateChanges(BuildContext context, UserState state) {
    switch (state.status) {
      case UserStatus.deleteSuccess:
      case UserStatus.saveSuccess:
      case UserStatus.viewSuccess:
        _refreshUserList(context);
        break;
      default:
        break;
    }
  }

  void _refreshUserList(BuildContext context) {
    final formState = _formKey.currentState;
    if (formState == null || formState.saveAndValidate()) {
      context.read<UserBloc>().add(_buildSearchEventFromForm(formState));
    }
  }
}

class UserListView extends StatelessWidget {
  const UserListView({super.key, required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        final items = state.status == UserStatus.searchSuccess ? state.userList : null;
        final isLoading = state.status == UserStatus.loading;

        return AppResponsiveListView<UserEntity>(
          title: S.of(context).list_user,
          subtitle: 'Browse and manage users in a table view.',
          items: items,
          isLoading: isLoading,
          onCreateNew: () => context.goNamed('userCreate', extra: {'fromRoute': ApplicationRoutesConstants.userList}),
          createNewKey: const Key('listUserCreateButtonKey'),
          createLabel: S.of(context).new_user,
          emptyIcon: Icons.people_outline,
          emptyText: S.of(context).list_user,
          showCheckbox: true,
          columns: _buildColumns(context),
          desktopSearchWidget: UserSearchSection(formKey: formKey),
          mobileSearchWidget: _MobileSearchBar(formKey: formKey),
          mobileCardBuilder: (context, user) => _MobileUserCard(user: user),
        );
      },
    );
  }

  List<AppTableColumn<UserEntity>> _buildColumns(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface);

    return [
      AppTableColumn<UserEntity>(
        label: S.of(context).active,
        flex: 2,
        builder: (ctx, user) {
          final isActive = user.activated == true;
          final color = isActive
              ? (Theme.of(ctx).extension<SemanticColors>()?.success ?? const Color(0xFF16A34A))
              : Theme.of(ctx).colorScheme.error;
          return AppStatusBadge(label: isActive ? 'Active' : 'Inactive', color: color);
        },
      ),
      AppTableColumn<UserEntity>(
        label: S.of(context).role,
        flex: 3,
        builder: (ctx, user) => Text(
          user.authorities?.contains('ROLE_ADMIN') == true ? S.of(ctx).admin : S.of(ctx).guest,
          style: cellStyle,
        ),
      ),
      AppTableColumn<UserEntity>(
        label: S.of(context).login,
        flex: 3,
        builder: (_, user) => Text(user.login.toString(), style: cellStyle),
      ),
      AppTableColumn<UserEntity>(
        label: S.of(context).first_name,
        flex: 3,
        builder: (_, user) => Text(user.firstName.toString(), style: cellStyle),
      ),
      AppTableColumn<UserEntity>(
        label: S.of(context).last_name,
        flex: 3,
        builder: (_, user) => Text(user.lastName.toString(), style: cellStyle),
      ),
      AppTableColumn<UserEntity>(
        label: S.of(context).email,
        flex: 4,
        builder: (_, user) => Text(user.email.toString(), style: cellStyle),
      ),
      AppTableColumn<UserEntity>(
        label: 'Actions',
        flex: 4,
        alignment: TextAlign.right,
        builder: (_, user) => _DesktopRowActions(userId: user.login ?? ''),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Desktop search section
// ---------------------------------------------------------------------------

class UserSearchSection extends StatelessWidget {
  const UserSearchSection({super.key, required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 980;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40, child: SearchNameField()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 200, height: 40, child: AuthoritiesDropdown(hintText: 'Role filter')),
                    const SizedBox(width: 8),
                    const SizedBox(width: 170, height: 40, child: PaginationControls()),
                    const Spacer(),
                    SearchActionButtons(formKey: formKey),
                    const SizedBox(width: 8),
                    const _ColumnsButton(),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: SizedBox(height: 40, child: SearchNameField())),
              const SizedBox(width: 8),
              const SizedBox(width: 200, height: 40, child: AuthoritiesDropdown(hintText: 'Role filter')),
              const SizedBox(width: 8),
              const SizedBox(width: 170, height: 40, child: PaginationControls()),
              const SizedBox(width: 8),
              SearchActionButtons(formKey: formKey),
              const SizedBox(width: 8),
              const _ColumnsButton(),
            ],
          );
        },
      ),
    );
  }
}

class PaginationControls extends StatelessWidget {
  const PaginationControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'rangeStart',
            initialValue: '0',
            textAlign: TextAlign.center,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: S.of(context).required_range),
              FormBuilderValidators.numeric(errorText: S.of(context).required_range),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '/',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: FormBuilderTextField(
            name: 'rangeEnd',
            initialValue: '100',
            textAlign: TextAlign.center,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: S.of(context).required_range),
              FormBuilderValidators.numeric(errorText: S.of(context).required_range),
            ]),
          ),
        ),
      ],
    );
  }
}

class SearchNameField extends StatelessWidget {
  const SearchNameField({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'name',
      decoration: InputDecoration(
        hintText: 'Filter users...',
        prefixIcon: Icon(Icons.search, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
      ),
      initialValue: '',
    );
  }
}

class SearchActionButtons extends StatelessWidget {
  const SearchActionButtons({super.key, required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('listUserSubmitButtonKey'),
      onPressed: () => _handleSearch(context),
      icon: const Icon(Icons.search, size: 16),
      label: Text(S.of(context).list),
      style: OutlinedButton.styleFrom(minimumSize: const Size(86, 40), maximumSize: const Size(120, 40)),
    );
  }

  void _handleSearch(BuildContext context) {
    if (formKey.currentState!.saveAndValidate()) {
      context.read<UserBloc>().add(_buildSearchEventFromForm(formKey.currentState));
    }
  }
}

class _ColumnsButton extends StatelessWidget {
  const _ColumnsButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.view_column_outlined, size: 16),
      label: const Text('Columns'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(104, 40), maximumSize: const Size(130, 40)),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile search bar
// ---------------------------------------------------------------------------

class _MobileSearchBar extends StatelessWidget {
  const _MobileSearchBar({required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Row(
        children: [
          const Expanded(child: SizedBox(height: 40, child: SearchNameField())),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => _handleSearch(context),
              icon: const Icon(Icons.search, size: 16),
              label: Text(S.of(context).list),
              style: OutlinedButton.styleFrom(minimumSize: const Size(86, 40), maximumSize: const Size(120, 40)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSearch(BuildContext context) {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      context.read<UserBloc>().add(_buildSearchEventFromForm(formKey.currentState));
    }
  }
}

// ---------------------------------------------------------------------------
// Mobile user card
// ---------------------------------------------------------------------------

class _MobileUserCard extends StatelessWidget {
  const _MobileUserCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isActive = user.activated == true;
    final isAdmin = user.authorities?.contains('ROLE_ADMIN') == true;
    final statusColor = isActive
        ? (Theme.of(context).extension<SemanticColors>()?.success ?? const Color(0xFF16A34A))
        : cs.error;

    final initial = (user.firstName?.isNotEmpty == true ? user.firstName![0] : '?').toUpperCase();
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    initial,
                    style: tt.titleSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : user.login ?? '',
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email!,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _onAction(context, value),
                  icon: Icon(Icons.more_vert, size: 22, color: cs.onSurfaceVariant),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18, color: cs.onSurface),
                          const SizedBox(width: 8),
                          Text(S.of(context).view_user),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: cs.onSurface),
                          const SizedBox(width: 8),
                          Text(S.of(context).edit_user),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: cs.error),
                          const SizedBox(width: 8),
                          Text(S.of(context).delete_user, style: TextStyle(color: cs.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AppStatusBadge(label: isActive ? 'Active' : 'Inactive', color: statusColor),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    isAdmin ? S.of(context).admin : S.of(context).guest,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (user.login != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '@${user.login}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAction(BuildContext context, String action) {
    final login = user.login ?? '';
    switch (action) {
      case 'view':
        context.goNamed('userView', pathParameters: {'id': login});
      case 'edit':
        context.goNamed('userEdit', pathParameters: {'id': login});
      case 'delete':
        _showDeleteConfirmation(context, login);
    }
  }

  void _showDeleteConfirmation(BuildContext context, String userId) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx).warning),
        content: Text(S.of(ctx).delete_confirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(ctx).no)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserBloc>().add(UserDeleteEvent(userId));
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            child: Text(S.of(ctx).yes),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop row actions
// ---------------------------------------------------------------------------

class _DesktopRowActions extends StatelessWidget {
  const _DesktopRowActions({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _GhostIconButton(icon: Icons.edit, onPressed: () => _edit(context), color: cs.onSurface),
          const SizedBox(width: 4),
          _GhostIconButton(icon: Icons.visibility, onPressed: () => _view(context), color: cs.onSurface),
          const SizedBox(width: 4),
          _GhostIconButton(icon: Icons.delete, onPressed: () => _delete(context), color: cs.error),
        ],
      ),
    );
  }

  void _edit(BuildContext context) => context.goNamed('userEdit', pathParameters: {'id': userId});
  void _view(BuildContext context) => context.goNamed('userView', pathParameters: {'id': userId});

  void _delete(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx).warning),
        content: Text(S.of(ctx).delete_confirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(ctx).no)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserBloc>().add(UserDeleteEvent(userId));
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            child: Text(S.of(ctx).yes),
          ),
        ],
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({required this.icon, required this.onPressed, required this.color});

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        padding: EdgeInsets.zero,
        splashRadius: 17,
        style: IconButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(34, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListUserScreen();
  }
}
