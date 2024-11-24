import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/bloc/register.dart';
import 'package:flutter_bloc_advance/presentation/screen/register/register_screen.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../test_utils.dart';

///Register User Screen Test
///class RegisterScreen extends StatelessWidget
void main() {
  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
  });

  final blocs = [
    BlocProvider<AccountBloc>(create: (_) => AccountBloc(accountRepository: AccountRepository())),
    BlocProvider<RegisterBloc>(create: (_) => RegisterBloc(accountRepository: AccountRepository())),
  ];

  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: blocs,
        child: RegisterScreen(),
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

  //validate AppBar and back button
  group("RegisterScreen Test", () {
    testWidgets("Validate AppBar", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(AppBar), findsOneWidget);
      // appBar title
      expect(find.text("Register"), findsNWidgets(1));
      expect(find.text("Save"), findsNWidgets(1));
      // back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    //validate form fields
    testWidgets("Validate Form Fields", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsNWidgets(3));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    //validate form fields enter text
    testWidgets("Validate Form Fields Enter Text", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      await tester.enterText(find.byType(FormBuilderTextField).first, "test");
      await tester.enterText(find.byType(FormBuilderTextField).at(1), "test");
      await tester.enterText(find.byType(FormBuilderTextField).last, "test@test.com");
    });

    //validate submit button
    testWidgets("Validate Submit Button", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    });

    //validate form fields enter text
    testWidgets("Validate Form Fields Enter Text and submit", (tester) async {
      TestUtils().setupAuthentication();
      // Given
      await tester.pumpWidget(getWidget());

      //When:
      await tester.pumpAndSettle();
      //Then:
      await tester.enterText(find.byType(FormBuilderTextField).first, "test");
      await tester.enterText(find.byType(FormBuilderTextField).at(1), "test");
      await tester.enterText(find.byType(FormBuilderTextField).last, "test@test.com");

      //when submitButton clicked then expect an error
      //tester.tap(find.byType(ElevatedButton));

      //await tester.pumpAndSettle();
    });
  });
}
