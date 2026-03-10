import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/features/users/application/user_bloc.dart';
import 'package:flutter_bloc_advance/features/users/presentation/widgets/authorities_dropdown.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/semantic_colors.dart';
import 'package:flutter_bloc_advance/shared/design_system/tokens/app_breakpoints.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppBreakpoints.isMobile(constraints.maxWidth)) {
          return UserMobileListView(formKey: formKey);
        }
        return SingleChildScrollView(
          child: UserListContent(formKey: formKey, horizontalPadding: 24, maxWidth: 1200),
        );
      },
    );
  }
}

class UserListContent extends StatelessWidget {
  const UserListContent({super.key, required this.formKey, required this.horizontalPadding, required this.maxWidth});

  final GlobalKey<FormBuilderState> formKey;
  final double horizontalPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
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
                    Text(S.of(context).list_user, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Browse and manage users in a table view.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                key: const Key('listUserCreateButtonKey'),
                onPressed: () =>
                    context.goNamed('userCreate', extra: {'fromRoute': ApplicationRoutesConstants.userList}),
                icon: const Icon(Icons.add, size: 16),
                label: Text(S.of(context).new_user),
              ),
            ],
          ),
          const SizedBox(height: 20),
          UserSearchSection(formKey: formKey),
          const SizedBox(height: 16),
          _DataTableContainer(formKey: formKey),
        ],
      ),
    );
  }
}

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

class _DataTableContainer extends StatelessWidget {
  const _DataTableContainer({required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          final rowCount = state.userList?.length ?? 0;
          return Column(
            children: [
              const _TableHeader(),
              _TableBody(formKey: formKey),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: cs.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$rowCount row(s) listed.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    OutlinedButton(onPressed: null, child: const Text('Previous')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: null, child: const Text('Next')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

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
          const SizedBox(width: 28, child: Checkbox(value: false, onChanged: null)),
          _HeadCell(flex: 2, text: S.of(context).active, style: style),
          _HeadCell(flex: 3, text: S.of(context).role, style: style),
          _HeadCell(flex: 3, text: S.of(context).login, style: style),
          _HeadCell(flex: 3, text: S.of(context).first_name, style: style),
          _HeadCell(flex: 3, text: S.of(context).last_name, style: style),
          _HeadCell(flex: 4, text: S.of(context).email, style: style),
          _HeadCell(flex: 4, text: 'Actions', style: style, alignment: TextAlign.right),
        ],
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell({required this.flex, required this.text, this.style, this.alignment = TextAlign.left});

  final int flex;
  final String text;
  final TextStyle? style;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text, textAlign: alignment, style: style, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state.status == UserStatus.searchSuccess && state.userList != null && state.userList!.isNotEmpty) {
          return Column(
            children: [
              for (int i = 0; i < state.userList!.length; i++)
                _TableRow(user: state.userList![i], isLast: i == state.userList!.length - 1, formKey: formKey),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({required this.user, required this.isLast, required this.formKey});

  final dynamic user;
  final bool isLast;
  final GlobalKey<FormBuilderState> formKey;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cellStyle = tt.bodySmall?.copyWith(color: cs.onSurface);
    final user = widget.user;

    final isActive = user.activated == true;
    final statusColor = isActive
        ? (Theme.of(context).extension<SemanticColors>()?.success ?? const Color(0xFF16A34A))
        : cs.error;

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
            const SizedBox(width: 28, child: Checkbox(value: false, onChanged: null)),
            _BodyCell(
              flex: 2,
              child: _StatusBadge(label: isActive ? 'Active' : 'Inactive', color: statusColor),
            ),
            _BodyCell(
              flex: 3,
              child: Text(
                user.authorities!.contains('ROLE_ADMIN') ? S.of(context).admin : S.of(context).guest,
                style: cellStyle,
              ),
            ),
            _BodyCell(flex: 3, child: Text(user.login.toString(), style: cellStyle)),
            _BodyCell(flex: 3, child: Text(user.firstName.toString(), style: cellStyle)),
            _BodyCell(flex: 3, child: Text(user.lastName.toString(), style: cellStyle)),
            _BodyCell(flex: 4, child: Text(user.email.toString(), style: cellStyle)),
            _BodyCell(
              flex: 4,
              alignment: CrossAxisAlignment.end,
              child: _RowActions(userId: user.login!, formKey: widget.formKey),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.flex, required this.child, this.alignment = CrossAxisAlignment.start});

  final int flex;
  final Widget child;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Align(
          alignment: alignment == CrossAxisAlignment.end ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(51), width: 0.5),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.userId, required this.formKey});

  final String userId;
  final GlobalKey<FormBuilderState> formKey;

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
              late final StreamSubscription<UserState> sub;
              sub = context.read<UserBloc>().stream.listen((state) {
                if (state.status == UserStatus.deleteSuccess && context.mounted) {
                  _refresh(context);
                  sub.cancel();
                }
              });
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            child: Text(S.of(ctx).yes),
          ),
        ],
      ),
    );
  }

  void _refresh(BuildContext context) {
    context.read<UserBloc>().add(_buildSearchEventFromForm(formKey.currentState));
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

class UserActionButtons extends StatelessWidget {
  const UserActionButtons({super.key, this.userId, this.username, required this.formKey});

  final String? userId;
  final String? username;
  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: _RowActions(userId: userId ?? username ?? '', formKey: formKey),
    );
  }
}

class UserTableCell extends StatelessWidget {
  const UserTableCell({
    super.key,
    required this.flex,
    required this.text,
    this.alignment = TextAlign.left,
    this.textColor,
  });

  final int flex;
  final String text;
  final TextAlign alignment;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignment,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: textColor != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class TableColumnHeader extends StatelessWidget {
  const TableColumnHeader({super.key, required this.flex, required this.title, this.alignment = TextAlign.left});

  final int flex;
  final String title;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: alignment,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class UserTableHeader extends StatelessWidget {
  const UserTableHeader({super.key});

  @override
  Widget build(BuildContext context) => const _TableHeader();
}

class UserTableContent extends StatelessWidget {
  const UserTableContent({super.key, required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) => _TableBody(formKey: formKey);
}

class UserTableRow extends StatelessWidget {
  const UserTableRow({super.key, required this.user, required this.index, required this.formKey, required this.isLast});

  final dynamic user;
  final int index;
  final GlobalKey<FormBuilderState> formKey;
  final bool isLast;

  @override
  Widget build(BuildContext context) => _TableRow(user: user, isLast: isLast, formKey: formKey);
}

class _MobileUserList extends StatelessWidget {
  const _MobileUserList({required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  S.of(context).list_user,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.icon(
                key: const Key('listUserCreateButtonKey'),
                onPressed: () => context.goNamed(
                  'userCreate',
                  extra: {'fromRoute': ApplicationRoutesConstants.userList},
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(S.of(context).new_user),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: FormBuilder(
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
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(86, 40),
                      maximumSize: const Size(120, 40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state.status == UserStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == UserStatus.searchSuccess && state.userList != null && state.userList!.isNotEmpty) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.userList!.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _MobileUserCard(user: state.userList![index], formKey: formKey);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${state.userList!.length} row(s) listed.',
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
                    Icon(Icons.people_outline, size: 48, color: cs.onSurfaceVariant.withAlpha(102)),
                    const SizedBox(height: 12),
                    Text(S.of(context).list_user, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleSearch(BuildContext context) {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      context.read<UserBloc>().add(_buildSearchEventFromForm(formKey.currentState));
    }
  }
}

class _MobileUserCard extends StatelessWidget {
  const _MobileUserCard({required this.user, required this.formKey});

  final dynamic user;
  final GlobalKey<FormBuilderState> formKey;

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
                        fullName.isNotEmpty ? fullName : user.login?.toString() ?? '',
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email.toString(),
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
                _StatusBadge(label: isActive ? 'Active' : 'Inactive', color: statusColor),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
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
    final login = user.login?.toString() ?? '';
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
              late final StreamSubscription<UserState> sub;
              sub = context.read<UserBloc>().stream.listen((state) {
                if (state.status == UserStatus.deleteSuccess && context.mounted) {
                  context.read<UserBloc>().add(_buildSearchEventFromForm(formKey.currentState));
                  sub.cancel();
                }
              });
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
            child: Text(S.of(ctx).yes),
          ),
        ],
      ),
    );
  }
}

class UserMobileListView extends StatelessWidget {
  const UserMobileListView({super.key, required this.formKey});

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) => _MobileUserList(formKey: formKey);
}

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListUserScreen();
  }
}
