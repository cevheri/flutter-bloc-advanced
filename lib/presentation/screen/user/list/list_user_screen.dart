import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

class ListUserScreen extends StatelessWidget {
  ListUserScreen({super.key});

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    _loadAuthority(context);
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _handleUserStateChanges,
      child: Scaffold(
        appBar: AppBar(title: Text(S.of(context).list_user)),
        body: const UserListView(),
      ),
    );
  }

  void _loadAuthority(BuildContext context) {
    BlocProvider.of<AuthorityBloc>(context).add(const AuthorityLoad());
  }

  void _handleUserStateChanges(BuildContext context, UserState state) {
    if (state.status == UserStatus.success) {
      _refreshUserList(context);
    }
  }

  void _refreshUserList(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      context.read<UserBloc>().add(
            UserSearch(
              int.parse(_formKey.currentState!.fields['rangeStart']?.value),
              int.parse(_formKey.currentState!.fields['rangeEnd']?.value),
              _formKey.currentState!.fields['authority']?.value ?? "-",
              _formKey.currentState!.fields['name']?.value ?? "",
            ),
          );
    }
  }
}

class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) => _buildResponsiveLayout(context, constraints),
      ),
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

class UserListContent extends StatelessWidget {
  final double horizontalPadding;
  final double maxWidth;
  final _formKey = GlobalKey<FormBuilderState>();

  UserListContent({
    super.key,
    required this.horizontalPadding,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          UserSearchSection(formKey: _formKey),
          const SizedBox(height: 30),
          const UserTableHeader(),
          UserTableContent(formKey: _formKey),
        ],
      ),
    );
  }
}

class UserSearchSection extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;

  const UserSearchSection({
    super.key,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 30, 10),
      child: FormBuilder(
        key: formKey,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(width: 75, child: Text(S.of(context).filter)),
              const Flexible(flex: 2, child: AuthorityDropdown()),
              const SizedBox(width: 10),
              const SizedBox(width: 200, child: PaginationControls()),
              const SizedBox(width: 10),
              const Flexible(child: SearchNameField()),
              const SizedBox(width: 10),
              SearchActionButtons(formKey: formKey),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthorityDropdown extends StatelessWidget {
  const AuthorityDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: BlocBuilder<AuthorityBloc, AuthorityState>(
        builder: (context, state) {
          if (state is AuthorityLoadSuccessState) {
            return FormBuilderDropdown(
              name: 'authority',
              decoration: InputDecoration(
                hintText: S.of(context).authorities,
              ),
              items: state.authorities!
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              initialValue: state.authorities![0],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

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
            const Text("/"),
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

class SearchNameField extends StatelessWidget {
  const SearchNameField({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: 'name',
      decoration: InputDecoration(hintText: S.of(context).name),
      initialValue: "",
    );
  }
}

class SearchActionButtons extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;

  const SearchActionButtons({
    super.key,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          key: const Key("listUserSubmitButtonKey"),
          style: _buttonStyle(),
          onPressed: () => _handleSearch(context),
          child: Text(S.of(context).list),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          key: const Key("listUserCreateButtonKey"),
          style: _buttonStyle(),
          onPressed: () => context.pushNamed('userCreate'),
          child: Text(S.of(context).new_user),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  void _handleSearch(BuildContext context) {
    if (formKey.currentState!.saveAndValidate()) {
      context.read<UserBloc>().add(
            UserSearch(
              int.parse(formKey.currentState!.fields['rangeStart']?.value),
              int.parse(formKey.currentState!.fields['rangeEnd']?.value),
              formKey.currentState!.fields['authority']?.value ?? "-",
              formKey.currentState!.fields['name']?.value ?? "",
            ),
          );
    }
  }
}

class UserTableHeader extends StatelessWidget {
  const UserTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TableColumnHeader(flex: 5, title: S.of(context).role),
            const SizedBox(width: 5),
            TableColumnHeader(flex: 3, title: S.of(context).login),
            const SizedBox(width: 5),
            TableColumnHeader(flex: 4, title: S.of(context).first_name),
            const SizedBox(width: 5),
            TableColumnHeader(flex: 4, title: S.of(context).last_name),
            const SizedBox(width: 5),
            TableColumnHeader(flex: 4, title: S.of(context).email),
            const SizedBox(width: 5),
            TableColumnHeader(flex: 3, title: S.of(context).active),
            const SizedBox(width: 5),
            const TableColumnHeader(flex: 3, title: "Actions"),
          ],
        ),
        const Divider(height: 2, color: Colors.grey, thickness: 1.5),
      ],
    );
  }
}

class TableColumnHeader extends StatelessWidget {
  final int flex;
  final String title;
  final TextAlign alignment;

  const TableColumnHeader({
    super.key,
    required this.flex,
    required this.title,
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: alignment,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class UserTableContent extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;

  const UserTableContent({
    super.key,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserSearchSuccessState) {
          return ListView.builder(
            itemCount: state.userList.length,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) => UserTableRow(
              user: state.userList[index],
              index: index,
              formKey: formKey,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class UserTableRow extends StatelessWidget {
  final dynamic user;
  final int index;
  final GlobalKey<FormBuilderState> formKey;

  const UserTableRow({
    super.key,
    required this.user,
    required this.index,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: _buildRowDecoration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          UserTableCell(flex: 5, text: _getRoleText(context)),
          const SizedBox(width: 5),
          UserTableCell(flex: 3, text: user.login.toString()),
          const SizedBox(width: 5),
          UserTableCell(flex: 4, text: user.firstName.toString()),
          const SizedBox(width: 5),
          UserTableCell(flex: 4, text: user.lastName.toString()),
          const SizedBox(width: 5),
          UserTableCell(flex: 4, text: user.email.toString()),
          const SizedBox(width: 5),
          UserTableCell(flex: 3, text: user.activated! ? "active" : "passive"),
          const SizedBox(width: 5),
          UserActionButtons(userId: user.id!, formKey: formKey),
        ],
      ),
    );
  }

  String _getRoleText(BuildContext context) {
    return user.authorities!.contains("ROLE_ADMIN") ? S.of(context).admin : S.of(context).guest;
  }

  BoxDecoration _buildRowDecoration(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isEvenRow = index % 2 == 0;

    if (isDarkMode) {
      return BoxDecoration(
        color: isEvenRow ? Colors.black26 : null,
      );
    }
    return BoxDecoration(
      color: isEvenRow ? Colors.blueGrey[50] : null,
    );
  }
}

class UserTableCell extends StatelessWidget {
  final int flex;
  final String text;
  final TextAlign alignment;

  const UserTableCell({
    super.key,
    required this.flex,
    required this.text,
    this.alignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: alignment),
    );
  }
}

class UserActionButtons extends StatelessWidget {
  final String userId;
  final GlobalKey<FormBuilderState> formKey;

  const UserActionButtons({
    super.key,
    required this.userId,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.edit,
            onPressed: () => _handleEdit(context),
          ),
          const SizedBox(width: 5),
          _buildActionButton(
            icon: Icons.visibility,
            onPressed: () => _handleView(context),
          ),
          const SizedBox(width: 5),
          _buildActionButton(
            icon: Icons.delete,
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
    );
  }

  void _handleEdit(BuildContext context) {
    context.pushNamed(
      'userEdit',
      pathParameters: {'id': userId},
    ).then((_) => _refreshList(context));
  }

  void _handleView(BuildContext context) {
    context.pushNamed(
      'userView',
      pathParameters: {'id': userId},
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).warning),
        content: Text(S.of(context).delete_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserBloc>().add(UserDeleteEvent(userId));
            },
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );
  }

  void _refreshList(BuildContext context) {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      context.read<UserBloc>().add(
            UserSearch(
              int.parse(formKey.currentState!.fields['rangeStart']?.value),
              int.parse(formKey.currentState!.fields['rangeEnd']?.value),
              formKey.currentState!.fields['authority']?.value ?? "-",
              formKey.currentState!.fields['name']?.value ?? "",
            ),
          );
    }
  }
}
