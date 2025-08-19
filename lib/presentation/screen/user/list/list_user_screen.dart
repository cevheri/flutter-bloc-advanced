import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/screen/components/authorities_lov_widget.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

/// Main screen widget for displaying user list functionality.
/// Handles authorities loading and user state changes.
/// Contains the main layout structure and search functionality.
class ListUserScreen extends StatelessWidget {
  ListUserScreen({super.key});

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _handleUserStateChanges,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceContainerLow],
            ),
          ),
          child: const UserListView(),
        ),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(S.of(context).list_user),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  void _handleUserStateChanges(BuildContext context, UserState state) {
    debugPrint("check: ${state.status}");
    switch (state.status) {
      case UserStatus.searchSuccess:
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
    debugPrint("checkpoint: refresh user list 1");
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      debugPrint("checkpoint: refresh user list 2");
      context.read<UserBloc>().add(const UserSearchEvent());
    }
  }
}

/// Responsible for creating responsive layout for the user list.
/// Adjusts the layout based on screen width constraints.
/// Shows error message if screen size is too small.
class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(builder: (context, constraints) => _buildResponsiveLayout(context, constraints)),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, BoxConstraints constraints) {
    if (constraints.maxWidth > 900) {
      return UserListContent(horizontalPadding: 200, maxWidth: 1100);
    } else if (constraints.maxWidth > 700) {
      return UserListContent(horizontalPadding: 200, maxWidth: 1200);
    }
    return Center(child: Text(S.of(context).screen_size_error));
  }
}

/// Contains the main content structure for the user list.
/// Manages the layout of search section, table header and content.
/// Handles padding and spacing of main components.
class UserListContent extends StatelessWidget {
  final double horizontalPadding;
  final double maxWidth;
  final _formKey = GlobalKey<FormBuilderState>();

  UserListContent({super.key, required this.horizontalPadding, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
      child: Column(
        spacing: 24,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserSearchSection(formKey: _formKey),
          const UserTableHeader(),
          UserTableContent(formKey: _formKey),
        ],
      ),
    );
  }
}

/// Search section widget that contains filtering options.
/// Includes authorities dropdown, pagination controls, and name search.
/// Manages form state for search parameters.
class UserSearchSection extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;

  const UserSearchSection({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: FormBuilder(
        key: formKey,
        child: IntrinsicHeight(
          child: Row(
            spacing: 16,
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: 80,
                child: Text(S.of(context).filter, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const Flexible(flex: 2, child: AuthoritiesDropdown()),
              const SizedBox(width: 200, child: PaginationControls()),
              const Flexible(child: SearchNameField()),
              SearchActionButtons(formKey: formKey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Handles pagination input controls.
/// Contains start and end range text fields.
/// Includes validation for numeric inputs.
class PaginationControls extends StatelessWidget {
  const PaginationControls({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: SizedBox(
        width: 200,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FormBuilderTextField(
                name: 'rangeStart',
                initialValue: "0",
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: S.of(context).required_range),
                  FormBuilderValidators.numeric(errorText: S.of(context).required_range),
                  FormBuilderValidators.minLength(1, errorText: S.of(context).required_range),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Text("/", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 10),
            Flexible(
              child: FormBuilderTextField(
                name: 'rangeEnd',
                initialValue: "100",
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: S.of(context).required_range),
                  FormBuilderValidators.numeric(errorText: S.of(context).required_range),
                  FormBuilderValidators.minLength(1, errorText: S.of(context).required_range),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text field widget for user name search functionality.
/// Provides filtering by user name.
class SearchNameField extends StatelessWidget {
  const SearchNameField({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'name',
      decoration: InputDecoration(
        hintText: S.of(context).name,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      initialValue: "",
    );
  }
}

/// Contains search and create user action buttons.
/// Handles search submission and navigation to create user screen.
/// Manages form validation before search.
class SearchActionButtons extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;

  const SearchActionButtons({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        OutlinedButton.icon(
          key: const Key("listUserSubmitButtonKey"),
          onPressed: () => _handleSearch(context),
          icon: const Icon(Icons.search, size: 18),
          label: Text(S.of(context).list),
          style: FilledButton.styleFrom( 
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          key: const Key("listUserCreateButtonKey"),
          onPressed: () => context.goNamed('userCreate', extra: {'fromRoute': ApplicationRoutesConstants.userList}),
          icon: const Icon(Icons.add, size: 18),
          label: Text(S.of(context).new_user),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _handleSearch(BuildContext context) {
    if (formKey.currentState!.saveAndValidate()) {
      context.read<UserBloc>().add(
        UserSearchEvent(
          page: int.parse(formKey.currentState!.fields['rangeStart']?.value),
          size: int.parse(formKey.currentState!.fields['rangeEnd']?.value),
          authorities: formKey.currentState!.fields['authorities']?.value,
          name: formKey.currentState!.fields['name']?.value,
        ),
      );
    }
  }
}

/// Displays the header row of the user table.
/// Shows column titles for user properties.
/// Manages layout and styling of header columns.
class UserTableHeader extends StatelessWidget {
  const UserTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        border: Border.all(color: colorScheme.outlineVariant),

      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TableColumnHeader(flex: 5, title: S.of(context).role),
              const SizedBox(width: 8),
              TableColumnHeader(flex: 3, title: S.of(context).login),
              const SizedBox(width: 8),
              TableColumnHeader(flex: 4, title: S.of(context).first_name),
              const SizedBox(width: 8),
              TableColumnHeader(flex: 4, title: S.of(context).last_name),
              const SizedBox(width: 8),
              TableColumnHeader(flex: 4, title: S.of(context).email),
              const SizedBox(width: 8),
              TableColumnHeader(flex: 3, title: S.of(context).active),
              const SizedBox(width: 8),
              const TableColumnHeader(flex: 3, title: "Actions"),
            ],
          ),
          //Divider(height: 1, color: colorScheme.outlineVariant, thickness: 1),
        ],
      ),
    );
  }
}

/// Reusable widget for table column headers.
/// Manages individual column header styling and layout.
/// Handles text alignment and flex sizing.
class TableColumnHeader extends StatelessWidget {
  final int flex;
  final String title;
  final TextAlign alignment;

  const TableColumnHeader({super.key, required this.flex, required this.title, this.alignment = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: alignment,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Displays the main content of the user table.
/// Renders user list data from UserBloc state.
/// Creates UserTableRow widgets for each user.
class UserTableContent extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;

  const UserTableContent({super.key, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state.status == UserStatus.searchSuccess) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: ListView.builder(
              itemCount: state.userList?.length,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) => UserTableRow(
                user: state.userList?[index],
                index: index,
                formKey: formKey,
                isLast: index == (state.userList?.length ?? 0) - 1,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Individual row widget for displaying user data.
/// Handles row styling (alternating colors).
/// Displays user properties and action buttons.
class UserTableRow extends StatelessWidget {
  final dynamic user;
  final int index;
  final GlobalKey<FormBuilderState> formKey;
  final bool isLast;

  const UserTableRow({super.key, required this.user, required this.index, required this.formKey, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _buildRowColor(context),
        borderRadius: isLast
            ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
            : null,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            UserTableCell(flex: 5, text: _getRoleText(context)),
            const SizedBox(width: 8),
            UserTableCell(flex: 3, text: user.login.toString()),
            const SizedBox(width: 8),
            UserTableCell(flex: 4, text: user.firstName.toString()),
            const SizedBox(width: 8),
            UserTableCell(flex: 4, text: user.lastName.toString()),
            const SizedBox(width: 8),
            UserTableCell(flex: 4, text: user.email.toString()),
            const SizedBox(width: 8),
            UserTableCell(
              flex: 3,
              text: user.activated! ? "Active" : "Inactive",
              textColor: user.activated! ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            UserActionButtons(userId: user.login!, formKey: formKey),
          ],
        ),
      ),
    );
  }

  String _getRoleText(BuildContext context) {
    return user.authorities!.contains("ROLE_ADMIN") ? S.of(context).admin : S.of(context).guest;
  }

  Color _buildRowColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEvenRow = index % 2 == 0;

    if (isEvenRow) {
      return colorScheme.surfaceContainerLowest;
    }
    return colorScheme.surface;
  }
}

/// Reusable cell widget for table data.
/// Manages individual cell content display.
/// Handles text alignment and flex sizing.
class UserTableCell extends StatelessWidget {
  final int flex;
  final String text;
  final TextAlign alignment;
  final Color? textColor;

  const UserTableCell({
    super.key,
    required this.flex,
    required this.text,
    this.alignment = TextAlign.left,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignment,
        style: textTheme.bodyMedium?.copyWith(
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: textColor != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Contains action buttons for each user row.
/// Handles edit, view, and delete operations.
/// Manages confirmation dialogs and navigation.
class UserActionButtons extends StatelessWidget {
  final String? userId;
  final String? username;
  final GlobalKey<FormBuilderState> formKey;

  const UserActionButtons({super.key, this.userId, this.username, required this.formKey});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.edit,
                onPressed: () => _handleEdit(context),
                size: constraints.maxWidth / 4,
                color: colorScheme.primary,
              ),
              _buildActionButton(
                icon: Icons.visibility,
                onPressed: () => _handleView(context),
                size: constraints.maxWidth / 4,
                color: colorScheme.secondary,
              ),
              _buildActionButton(
                icon: Icons.delete,
                onPressed: () => _showDeleteConfirmation(context),
                size: constraints.maxWidth / 4,
                color: colorScheme.error,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(maxWidth: size, maxHeight: size),
        icon: Icon(icon, size: 16, color: color),
        onPressed: onPressed,
      ),
    );
  }

  void _handleEdit(BuildContext context) {
    context.goNamed('userEdit', pathParameters: {'id': userId ?? username ?? ""});
  }

  void _handleView(BuildContext context) {
    context.goNamed('userView', pathParameters: {'id': userId ?? username ?? ""});
  }

  void _showDeleteConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: colorScheme.error),
            const SizedBox(width: 8),
            Text(S.of(context).warning),
          ],
        ),
        content: Text(S.of(context).delete_confirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(S.of(context).no)),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserBloc>().add(UserDeleteEvent(userId ?? username ?? ""));
              late final StreamSubscription<UserState> subscription;
              subscription = context.read<UserBloc>().stream.listen((state) {
                if (state.status == UserStatus.deleteSuccess && context.mounted) {
                  _refreshList(context);
                  subscription.cancel();
                }
              });
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );
  }

  void _refreshList(BuildContext context) {
    context.read<UserBloc>().add(
      UserSearchEvent(
        page: int.parse(formKey.currentState!.fields['rangeStart']?.value),
        size: int.parse(formKey.currentState!.fields['rangeEnd']?.value),
        authorities: formKey.currentState!.fields['authorities']?.value,
        name: formKey.currentState!.fields['name']?.value,
      ),
    );
  }
}
