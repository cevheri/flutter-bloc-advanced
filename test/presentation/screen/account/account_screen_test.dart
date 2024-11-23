
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/app_logger.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/account/account_screen.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import '../../../test_utils.dart';

final _log = AppLogger.getLogger("AccountsScreenTest");

/// Accounts Screen Test
/// claas AccountsScreen extent
void main() {
  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  final blocs = [
    BlocProvider<UserBloc>(create: (_) => UserBloc(userRepository: UserRepository())),
    BlocProvider<AuthorityBloc>(create: (_) => AuthorityBloc(authorityRepository: AuthorityRepository())),
    BlocProvider<AccountBloc>(create: (context) => AccountBloc(accountRepository: AccountRepository())..add(const AccountLoad()))
  ];

  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: blocs,
        child: AccountsScreen(),
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

  // app bar
  group("AccountsScreen AppBarTest", () {
    testWidgets("Validate AppBar", (tester) async {
      _log.debug("begin Validate AppBar");
      // Given
      await tester.pumpWidget(getWidget());
      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      // appBar title
      expect(find.text("Account"), findsOneWidget);

      _log.debug("end Validate AppBar");
    });
  });

  //form fields
  group("AccountsScreen DataTest", () {
    testWidgets("Render Screen Validate Field Type Successful", (tester) async {
      _log.debug("begin Validate Field Type");
      await TestUtils().setupAuthentication();
      _log.debug("getAccount initWidgetDependenciesWithToken");
      // Given:
      await tester.pumpWidget(getWidget());
      _log.debug("getAccount getWidget");
      //When:
      await tester.pumpAndSettle();
      _log.debug("getAccount pumpAndSettle");

      //Then:
      expect(find.byType(FormBuilderTextField), findsNWidgets(4)); // findsNWidget = 4?
      //expect(find.byType(FormBuilderSwitch), findsOneWidget);
      //expect(find.byType(ElevatedButton), findsOneWidget);
      _log.debug("end Validate Field Type");
    });

    /// validate field name with English translation
    testWidgets(skip: true, "Render Screen Validate Field Name Successful", (tester) async {
      //Given
      await tester.pumpWidget(getWidget());
      //When
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

    ///Validate Mock Data
    testWidgets(skip: true, "Render Screen Validate User Data Successful", (tester) async {
      // Given:
      /*await tester.pumpWidget(getWidget(mockUserFullPayload));
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
      expect(find.text("true"), findsOneWidget);*/
    });
  });

  group("AccountScreen Bloc Test", () {
    testWidgets(skip: true, "Given valid user data with AccessToken when Save Button clicked then update user Successfully", (tester) async {
      // Given: render screen with valid user data
      await tester.pumpWidget(getWidget());
      //When: wait screen is ready
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("Save"), findsOneWidget);
      //await tester.tap(find.text('Save'));
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
