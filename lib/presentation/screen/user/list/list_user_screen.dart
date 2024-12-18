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
  final _headerStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AuthorityBloc>(context).add(const AuthorityLoad());
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == UserStatus.success) {
          _refreshList(context);
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(title: Text(S.of(context).list_user));
  }

  _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return layoutBody(context, 200, 1100, constraints.maxWidth);
          } else if (constraints.maxWidth > 700 && constraints.maxWidth < 900) {
            return layoutBody(context, 200, 1200, constraints.maxWidth);
          } else {
            return Center(child: Text(S.of(context).screen_size_error));
          }
        },
      ),
    );
  }

  Widget layoutBody(BuildContext context, double min, double max, double maxWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _tableSearch(min, max, maxWidth, context),
          const SizedBox(height: 30),
          _tableHeader(context),
          _tableData(context),
        ],
      ),
    );
  }

  BlocBuilder<UserBloc, UserState> _tableData(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserSearchSuccessState) {
          return ListView.builder(
            itemCount: state.userList.length,
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                height: 50,
                decoration: buildTableRowDecoration(index, context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    _tableDataAuthority(state, index, context),
                    const SizedBox(width: 5),
                    _tableDataLogin(state, index),
                    const SizedBox(width: 5),
                    _tableDataFirsName(state, index),
                    const SizedBox(width: 5),
                    _tableDataLastName(state, index),
                    const SizedBox(width: 5),
                    _tableDataEmail(state, index),
                    const SizedBox(width: 5),
                    _tableDataActivatedSwitch(state, index),
                    const SizedBox(width: 5),
                    _tableDataActionButtons(context, state, index),
                    const SizedBox(width: 5),
                  ],
                ),
              );
            },
          );
        } else {
          return Container();
        }
      },
    );
  }

  Expanded _tableDataActivatedSwitch(UserSearchSuccessState state, int index) =>
      Expanded(flex: 3, child: Text(state.userList[index].activated! ? "active" : "passive"));

  Expanded _tableDataEmail(UserSearchSuccessState state, int index) =>
      Expanded(flex: 15, child: Text(state.userList[index].email.toString(), textAlign: TextAlign.left));

  Expanded _tableDataLastName(UserSearchSuccessState state, int index) =>
      Expanded(flex: 10, child: Text(state.userList[index].lastName.toString(), textAlign: TextAlign.left));

  Expanded _tableDataFirsName(UserSearchSuccessState state, int index) =>
      Expanded(flex: 10, child: Text(state.userList[index].firstName.toString(), textAlign: TextAlign.left));

  Expanded _tableDataLogin(UserSearchSuccessState state, int index) =>
      Expanded(flex: 10, child: Text(state.userList[index].login.toString(), textAlign: TextAlign.left));

  Expanded _tableDataAuthority(UserSearchSuccessState state, int index, BuildContext context) {
    return Expanded(
        flex: 7,
        child: Text(state.userList[index].authorities!.contains("ROLE_ADMIN") ? S.of(context).admin : S.of(context).guest,
            textAlign: TextAlign.left));
  }

  Widget _tableHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          verticalDirection: VerticalDirection.down,
          children: [
            Expanded(
              flex: 7,
              child: Text(S.of(context).role, textAlign: TextAlign.left, style: _headerStyle),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 10,
              child: Text(S.of(context).login, textAlign: TextAlign.left, style: _headerStyle),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 10,
              child: Text(S.of(context).first_name, textAlign: TextAlign.left, style: _headerStyle),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 10,
              child: Text(S.of(context).last_name, textAlign: TextAlign.left, style: _headerStyle),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 15,
              child: Text(S.of(context).email, textAlign: TextAlign.left, style: _headerStyle),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 3,
              child: Text(S.of(context).active, textAlign: TextAlign.center, style: _headerStyle),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 3,
              child: Container(),
            ),
            const SizedBox(width: 5),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(
          height: 2,
          color: Colors.grey,
          thickness: 1.5,
        ),
      ],
    );
  }

  BoxDecoration buildTableRowDecoration(int index, BuildContext context) {
    // dark or light mode row decoration
    if (Theme.of(context).brightness == Brightness.dark) {
      if (index % 2 == 0) {
        return const BoxDecoration(color: Colors.black26);
      } else {
        return const BoxDecoration();
      }
    } else {
      if (index % 2 == 0) {
        return BoxDecoration(color: Colors.blueGrey[50]);
      } else {
        return const BoxDecoration();
      }
    }
  }

  Widget _tableSearch(double min, double max, double maxWidth, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 30, 10),
      child: FormBuilder(
        key: _formKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: BlocBuilder<AuthorityBloc, AuthorityState>(
                  builder: (context, state) {
                    return _tableSearchAuthority(state, context);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            _tableSearchPage(context),
            const SizedBox(width: 10),
            const Flexible(
              child: Text("/"),
            ),
            const SizedBox(width: 10),
            _tableSearchSize(context),
            const SizedBox(width: 10),
            _tableSearchName(context),
            const SizedBox(width: 10),
            _submitButton(context),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                key: const Key("listUserCreateButtonKey"),
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(S.of(context).new_user),
                onPressed: () => context.pushNamed('userCreate'),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(flex: 3, child: Container()),
          ],
        ),
      ),
    );
  }

  Expanded _tableSearchName(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: FormBuilderTextField(
          name: 'name',
          decoration: InputDecoration(hintText: S.of(context).name),
          initialValue: "",
        ),
      ),
    );
  }

  Expanded _tableSearchSize(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: FormBuilderTextField(
          name: 'rangeEnd',
          initialValue: "100",
          validator: FormBuilderValidators.compose(
            [
              FormBuilderValidators.required(errorText: S.of(context).required_range),
              FormBuilderValidators.numeric(errorText: S.of(context).required_range),
              FormBuilderValidators.minLength(1, errorText: S.of(context).required_range),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _tableSearchPage(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: FormBuilderTextField(
          name: 'rangeStart',
          initialValue: "0",
          validator: FormBuilderValidators.compose(
            [
              FormBuilderValidators.required(errorText: S.of(context).required_range),
              FormBuilderValidators.numeric(errorText: S.of(context).required_range),
              FormBuilderValidators.minLength(1, errorText: S.of(context).required_range),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableSearchAuthority(AuthorityState state, BuildContext context) {
    if (state is AuthorityLoadSuccessState) {
      return FormBuilderDropdown(
        name: 'authority',
        decoration: InputDecoration(
          hintText: S.of(context).authorities,
        ),
        items: state.authorities!
            .map(
              (role) => DropdownMenuItem(
                value: role,
                child: Text(role),
              ),
            )
            .toList(),
        initialValue: state.authorities![0],
      );
    } else {
      return Container();
    }
  }

  _submitButton(BuildContext context) {
    return ElevatedButton(
      key: const Key("listUserSubmitButtonKey"),
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Text(S.of(context).list),
      onPressed: () {
        if (_formKey.currentState!.saveAndValidate()) {
          BlocProvider.of<UserBloc>(context).add(
            UserSearch(
              int.parse(_formKey.currentState!.fields['rangeStart']?.value),
              int.parse(_formKey.currentState!.fields['rangeEnd']?.value),
              _formKey.currentState!.fields['authority']?.value ?? "-",
              _formKey.currentState!.fields['name']?.value ?? "",
            ),
          );
        }
      },
    );
  }

  Widget _tableDataActionButtons(BuildContext context, UserSearchSuccessState state, int index) {
    return Expanded(
        flex: 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                context.pushNamed(
                  'userEdit',
                  pathParameters: {'id': state.userList[index].id!},
                ).then((_) => _refreshList(context));
              },
            ),
            const SizedBox(width: 5),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () {
                context.pushNamed(
                  'userView',
                  pathParameters: {'id': state.userList[index].id!},
                );
              },
            ),
            const SizedBox(width: 5),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _showDeleteConfirmation(context, state.userList[index].id!),
            ),
          ],
        ));
  }

  void _showDeleteConfirmation(BuildContext context, String userId) {
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
