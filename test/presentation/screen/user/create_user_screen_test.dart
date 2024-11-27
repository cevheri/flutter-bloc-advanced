import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/create/create_user_screen.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import '../../../test_utils.dart';

///Create User Screen Test
///class CreateUserScreen extent
void main() {
  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  final blocs = [
    BlocProvider<AuthorityBloc>(create: (_) => AuthorityBloc(repository: AuthorityRepository())),
    BlocProvider<AccountBloc>(create: (_) => AccountBloc(repository: AccountRepository())),
    BlocProvider<UserBloc>(create: (_) => UserBloc(userRepository: UserRepository())),
  ];
  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: blocs,
        child: CreateUserScreen(),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
  //endregion setup

  group("CreateUserScreen Test", () {
    testWidgets("Validate AppBar", (tester) async {
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      // appBar title
      //expect(find.text("Create User"), findsOneWidget);
    });

    testWidgets("Render Screen Validate Field Type Successful", (tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(FormBuilderTextField), findsNWidgets(4));
      expect(find.byType(FormBuilderSwitch), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
    });

    /// validate field name with English translation
    testWidgets("Render screen validate Field name successful", (tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      //username / login name textField
      expect(find.text('Login'), findsOneWidget);
      // firstName textField
      expect(find.text("First Name"), findsOneWidget);
      // lastName textField
      expect(find.text("Last Name"), findsOneWidget);
      // email textField
      expect(find.text("Email"), findsOneWidget);
      //Phone Number textField
      //expect(find.text("phoneNumber"), findsOneWidget);
      // active switch button
      expect(find.text("Active"), findsOneWidget);
      // save button
      //expect(find.text("Create User"), findsOneWidget);
    });

    /// validate mock data
    testWidgets("Render screen validate entered user data successful", (tester) async {
      // Given:
      await tester.pumpWidget(getWidget());
      await tester.pumpAndSettle();

      final formFinder = find.byType(FormBuilder);
      final formState = tester.state<FormBuilderState>(formFinder);

      final loginFinder = find.byKey(const Key("loginTextField"));
      final firstNameFinder = find.byKey(const Key("firstNameTextField"));
      final lastNameFinder = find.byKey(const Key("lastNameTextField"));
      final emailFinder = find.byKey(const Key("emailTextField"));
      final activeFinder = find.byKey(const Key("activeSwitch"));
      final updatedSwitchWidget = tester.widget<FormBuilderSwitch>(activeFinder);
      expect(updatedSwitchWidget.initialValue, equals(true));

      // final saveButtonFinder = find.byKey(const Key("createUserSubmitButton"));
      debugPrint("Found");

      await tester.pumpAndSettle();
      //When
      await tester.enterText(loginFinder, "admin");
      await tester.enterText(firstNameFinder, "Admin");
      await tester.enterText(lastNameFinder, "User");
      await tester.enterText(emailFinder, "admin@sekoya.tech");

      debugPrint("entered");

      //Then:
      formState.save();
      expect(formState.value['userCreateActive'], equals(true));

      expect(find.text("admin"), findsOneWidget);
      expect(find.text("Admin"), findsOneWidget);
      expect(find.text("User"), findsOneWidget);
      expect(find.text("admin@sekoya.tech"), findsOneWidget);

      await tester.tap(activeFinder);
      formState.save();
      await tester.pumpAndSettle();
      expect(formState.value['userCreateActive'], equals(false));
    });
  });

  /// validate mock data
  testWidgets(skip: true, "Render screen validate entered user data and click save button", (tester) async {
    await TestUtils().setupAuthentication();
    // Given:
    await tester.pumpWidget(getWidget());
    await tester.pumpAndSettle();

    final formFinder = find.byType(FormBuilder);
    final formState = tester.state<FormBuilderState>(formFinder);

    final loginFinder = find.byKey(const Key("loginTextField"));
    final firstNameFinder = find.byKey(const Key("firstNameTextField"));
    final lastNameFinder = find.byKey(const Key("lastNameTextField"));
    final emailFinder = find.byKey(const Key("emailTextField"));
    final activeFinder = find.byKey(const Key("activeSwitch"));
    final updatedSwitchWidget = tester.widget<FormBuilderSwitch>(activeFinder);
    expect(updatedSwitchWidget.initialValue, equals(true));

    final saveButtonFinder = find.byKey(const Key("createUserSubmitButton"));
    debugPrint("Found");

    await tester.pumpAndSettle();
    //When
    await tester.enterText(loginFinder, "admin");
    await tester.enterText(firstNameFinder, "Admin");
    await tester.enterText(lastNameFinder, "User");
    await tester.enterText(emailFinder, "admin@sekoya.tech");

    debugPrint("entered");

    //Then:
    formState.save();
    expect(formState.value['userCreateActive'], equals(true));

    expect(find.text("admin"), findsOneWidget);
    expect(find.text("Admin"), findsOneWidget);
    expect(find.text("User"), findsOneWidget);
    expect(find.text("admin@sekoya.tech"), findsOneWidget);

    await tester.tap(saveButtonFinder);

  });


  group("CreateUserScreen Bloc Test", () {
    testWidgets(skip: true, "Given valid user data with AccessToken when Save Button clicked then update user Successfully", (tester) async {
      // Given: render screen with valid user data
      await tester.pumpWidget(getWidget());
      //When: wait screen is ready
      await tester.pumpAndSettle();

      //expect(find.byType(ElevatedButton), findsOneWidget);
      //expect(find.text("Save"), findsOneWidget);
      await tester.tap(find.text('Save'));
      // await tester.pumpAndSettle();
    });

    testWidgets(skip: true, "Given valid user data without AccessToken when Save Button clicked then update user fail (Unauthorized)",
        (tester) async {
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);
      // await tester.tap(find.text('Save'));
      // await tester.pumpAndSettle();
      // Given: render screen with valid user data
      await tester.pumpWidget(getWidget());
      //When: wait screen is ready
      await tester.pumpAndSettle();

      //await tester.tap(find.text('Save'));
      //await tester.pumpAndSettle();
    });

    testWidgets(skip: true, "Given same user data (no-changes) when Save Button clicked then no-action", (tester) async {
      // Given: render screen with valid user data
      await tester.pumpWidget(getWidget());
      //When: wait screen is ready
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);

      await tester.tap(find.text('Save'));
    });
  });
}
