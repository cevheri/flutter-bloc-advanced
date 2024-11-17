import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/models/user.dart';
import 'package:flutter_bloc_advance/data/repository/authorities_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authorities/authorities_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/edit/edit_user_screen.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import '../../../fake/user_data.dart';
import '../../../test_utils.dart';

/// Edit User Screen Test
/// class UserScreen extends
void main() {
  //region init
  setUp(() {
    TestUtils.initBlocDependencies();
  });

  final blocs = [
    BlocProvider<AuthoritiesBloc>(create: (_) => AuthoritiesBloc(authoritiesRepository: AuthoritiesRepository())),
    BlocProvider<UserBloc>(create: (_) => UserBloc(userRepository: UserRepository())),
  ];

  GetMaterialApp getWidget(User user) {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: blocs,
        child: EditUserScreen(user: user),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
  //endregion init

  group("EditUserScreen Test", () {
    testWidgets("Validate AppBar", (tester) async {
      TestUtils.initWidgetDependencies();

      // Given:
      await tester.pumpWidget(getWidget(mockUserFullPayload));
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      // appBar title
      expect(find.text("Edit User"), findsOneWidget);
    });

    testWidgets("Render screen validate field type successful", (tester) async {
      TestUtils.initWidgetDependencies();
      // Given:
      await tester.pumpWidget(getWidget(mockUserFullPayload));
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(FormBuilderTextField), findsNWidgets(4));
      expect(find.byType(FormBuilderSwitch), findsOneWidget);
      // expect(find.byType(FormBuilderDropdown), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    /// validate field name with English translation
    testWidgets("Render screen validate field name successful", (tester) async {
      TestUtils.initWidgetDependencies();
      // Given:
      await tester.pumpWidget(getWidget(mockUserFullPayload));
      //When:
      await tester.pumpAndSettle();
      //Then:
      // username / login name textField
      expect(find.text("Login"), findsOneWidget);
      // firstName textField
      expect(find.text("First Name"), findsOneWidget);
      // lastName textField
      expect(find.text("Last Name"), findsOneWidget);
      // email textField
      expect(find.text("Email"), findsOneWidget);
      // active switch button
      expect(find.text("Active"), findsOneWidget);
      // save button
      expect(find.text("Save"), findsOneWidget);
    });

    /// validate mock data
    testWidgets("Render screen validate user data successful", (tester) async {
      TestUtils.initWidgetDependencies();
      // Given:
      await tester.pumpWidget(getWidget(mockUserFullPayload));
      //When:
      await tester.pumpAndSettle();
      //Then:
      // username / login name
      expect(find.text("test_login"), findsOneWidget);
      // firstName
      expect(find.text("John"), findsOneWidget);
      // lastName
      expect(find.text("Doe"), findsOneWidget);
      // email
      expect(find.text("john.doe@example.com"), findsOneWidget);
      // activated
      // expect(find.text("true"), findsOneWidget);
    });
  });

  group("EditUserScreen Bloc Test", () {
    testWidgets(skip: true, "Given valid user data with AccessToken when Save Button clicked then update user Successfully", (tester) async {
      TestUtils.initWidgetDependenciesWithToken();

      // Given: render screen with valid user data
      await tester.pumpWidget(getWidget(mockUserFullPayload));
      //When: wait screen is ready
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);
      //await tester.tap(find.text('Save'));
      // await tester.pumpAndSettle();
    });

    testWidgets(skip: true, "Given valid user data without AccessToken when Save Button clicked then update user fail (Unauthorized)",
        (tester) async {
      TestUtils.initWidgetDependencies();
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);
      // await tester.tap(find.text('Save'));
      // await tester.pumpAndSettle();
      // Given: render screen with valid user data
      await tester.pumpWidget(getWidget(mockUserFullPayload));
      //When: wait screen is ready
      await tester.pumpAndSettle();

      //await tester.tap(find.text('Save'));
      //await tester.pumpAndSettle();
    });

    testWidgets(skip: true, "Given same user data (no-changes) when Save Button clicked then no-action", (tester) async {
      TestUtils.initWidgetDependenciesWithToken();
      // Given: render screen with valid user data
      await tester.pumpWidget(getWidget(mockUserFullPayload));
      //When: wait screen is ready
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);

      await tester.tap(find.text('Save'));
    });
  });
}
