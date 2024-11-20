//ListUserScreen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../../generated/l10n.dart';
import '../../../common_blocs/authority/authority_bloc.dart';
import '../bloc/user_bloc.dart';
import '../edit/edit_user_screen.dart';

class ListUserScreen extends StatelessWidget {
  ListUserScreen({super.key});

  final listFormKey = GlobalKey<FormBuilderState>();
  final headerStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<AuthorityBloc>(context).add(AuthorityLoad());
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
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
      padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          _tableSearch(min, max, maxWidth, context),
          SizedBox(height: 30),
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
            physics: ClampingScrollPhysics(),
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
                    SizedBox(width: 5),
                    _tableDataLogin(state, index),
                    SizedBox(width: 5),
                    _tableDataFirsName(state, index),
                    SizedBox(width: 5),
                    _tableDataLastName(state, index),
                    SizedBox(width: 5),
                    _tableDataEmail(state, index),
                    // SizedBox(width: 5),
                    // Expanded(
                    //   flex: 10,
                    //   child: Text(
                    //       state.userList[index].phoneNumber.toString() == "null" ? "-" : state.userList[index].phoneNumber.toString(),
                    //       textAlign: TextAlign.left),
                    // ),
                    SizedBox(width: 5),
                    _tableDataActivatedSwitch(state, index),
                    SizedBox(width: 5),
                    _tableDataEditButton(context, state, index),
                    SizedBox(width: 5),
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

  Expanded _tableDataEditButton(BuildContext context, UserSearchSuccessState state, int index) {
    return Expanded(
      flex: 3,
      child: IconButton(
        alignment: Alignment.centerRight,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        icon: Icon(Icons.edit),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditUserScreen(user: state.userList[index])),
          ).then((value) async {
            if (listFormKey.currentState!.saveAndValidate()) {
              if (context.mounted) {
                BlocProvider.of<UserBloc>(context).add(
                  UserSearch(
                    int.parse(listFormKey.currentState!.fields['rangeStart']?.value),
                    int.parse(listFormKey.currentState!.fields['rangeEnd']?.value),
                    listFormKey.currentState!.fields['authority']?.value ?? "-",
                    listFormKey.currentState!.fields['name']?.value ?? "",
                  ),
                );
              }
            }
          });
        },
      ),
    );
  }

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
              child: Text(S.of(context).role, textAlign: TextAlign.left, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 10,
              child: Text(S.of(context).login, textAlign: TextAlign.left, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 10,
              child: Text(S.of(context).first_name, textAlign: TextAlign.left, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 10,
              child: Text(S.of(context).last_name, textAlign: TextAlign.left, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 15,
              child: Text(S.of(context).email, textAlign: TextAlign.left, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 10,
              child: Text(S.of(context).phone_number, textAlign: TextAlign.left, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 3,
              child: Text(S.of(context).guest, textAlign: TextAlign.left, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 3,
              child: Text(S.of(context).active, textAlign: TextAlign.center, style: headerStyle),
            ),
            SizedBox(width: 5),
            Expanded(
              flex: 3,
              child: Container(),
            ),
            SizedBox(width: 5),
          ],
        ),
        SizedBox(height: 10),
        Divider(
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
        return BoxDecoration(color: Colors.black26);
      } else {
        return BoxDecoration();
      }
    } else {
      if (index % 2 == 0) {
        return BoxDecoration(color: Colors.blueGrey[50]);
      } else {
        return BoxDecoration();
      }
    }
  }

  Widget _tableSearch(double min, double max, double maxWidth, BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 30, 10),
      child: FormBuilder(
        key: listFormKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: BlocBuilder<AuthorityBloc, AuthorityState>(
                  builder: (context, state) {
                    return _tableSearchAuthority(state, context);
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            _tableSearchPage(context),
            SizedBox(width: 10),
            Flexible(
              child: Text("/"),
            ),
            SizedBox(width: 10),
            _tableSearchSize(context),
            SizedBox(width: 10),
            _tableSearchName(context),
            SizedBox(width: 10),
            _submitButton(context),
            Expanded(flex: 3, child: Container()),
          ],
        ),
      ),
    );
  }

  Expanded _tableSearchName(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 10),
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
        padding: EdgeInsets.only(right: 10),
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
        padding: EdgeInsets.only(right: 10),
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
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Text(S.of(context).list),
      onPressed: () {
        if (listFormKey.currentState!.saveAndValidate()) {
          BlocProvider.of<UserBloc>(context).add(
            UserSearch(
              int.parse(listFormKey.currentState!.fields['rangeStart']?.value),
              int.parse(listFormKey.currentState!.fields['rangeEnd']?.value),
              listFormKey.currentState!.fields['authority']?.value ?? "-",
              listFormKey.currentState!.fields['name']?.value ?? "",
            ),
          );
        }
      },
    );
  }
}
