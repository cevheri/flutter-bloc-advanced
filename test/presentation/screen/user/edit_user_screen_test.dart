//TODO: user edit screen test will be removed
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_bloc_advance/data/models/user.dart';
// import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
// import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
// import 'package:flutter_bloc_advance/generated/l10n.dart';
// import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart';
// import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user_bloc.dart';
// import 'package:flutter_bloc_advance/presentation/screen/user/edit/edit_user_screen.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:get/get_navigation/src/root/get_material_app.dart';
//
// import '../../../fake/user_data.dart';
// import '../../../test_utils.dart';
//
// /// Edit User Screen Test
// /// class UserScreen extends
// void main() {
//   // 1. setup
//   // 2. appbar
//   // 3. render screen with field type( text, switch, dropdown, button, label, etc.)
//   // 4. validate field name with English translation
//   // 5. Optional: validate loaded data
//   // 6. Optional: Enter data to fields
//   // 8. Optional: Validate data entered
//   // 9. Validate button click or bloc event
//   // 10. Optional: Validate saved data, listed data, updated data, etc.
//   // 11. Validate screen dispose: back button, saved data, etc.
//
//   //region setup
//
//   // before
//   // setupAll run once before all tests
//   setUpAll(() async {
//     debugPrint("setupAll run once before all tests");
//     await TestUtils().setupUnitTest();
//   });
//
//   // after
//   // tearDownAll run once after all tests
//   tearDownAll(() async {
//     debugPrint("tearDownAll run once after all tests");
//   });
//
//   // setup run before each test
//   setUp(() async {
//     debugPrint("setUp run before each test");
//   });
//
//   // tearDown run after each test
//   tearDown(() async {
//     await TestUtils().tearDownUnitTest();
//     debugPrint("tearDown run after each test");
//   });
//
//   final blocs = [
//     BlocProvider<AuthorityBloc>(create: (_) => AuthorityBloc(repository: AuthorityRepository())),
//     BlocProvider<UserBloc>(create: (_) => UserBloc(repository: UserRepository())),
//   ];
//
//   GetMaterialApp getWidget(User user) {
//     return GetMaterialApp(
//       home: MultiBlocProvider(providers: blocs, child: EditUserScreen(id: user.id!)),
//       localizationsDelegates: const [
//         S.delegate,
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//     );
//   }
//   //endregion setup
//
//   group("EditUserScreen Test", () {
//     testWidgets("Validate AppBar", (tester) async {
//       // Given:
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       //When:
//       await tester.pumpAndSettle();
//       //Then:
//       expect(find.byType(AppBar), findsOneWidget);
//       expect(find.byType(IconButton), findsOneWidget);
//       // appBar title
//       expect(find.text("Edit User"), findsOneWidget);
//
//       //find back button
//       expect(find.byIcon(Icons.arrow_back), findsOneWidget);
//
//       //press back button
//       await tester.tap(find.byIcon(Icons.arrow_back));
//     });
//
//     testWidgets("Render screen validate field type successful", (tester) async {
//       // Given:
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       //When:
//       await tester.pumpAndSettle();
//       //Then:
//       expect(find.byType(FormBuilderTextField), findsNWidgets(4));
//       expect(find.byType(FormBuilderSwitch), findsOneWidget);
//       // expect(find.byType(FormBuilderDropdown), findsOneWidget);
//       expect(find.byType(ElevatedButton), findsOneWidget);
//     });
//
//     /// validate field name with English translation
//     testWidgets("Render screen validate field name successful", (tester) async {
//       // Given:
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       //When:
//       await tester.pumpAndSettle();
//       //Then:
//       expect(find.text("Login"), findsOneWidget);
//       expect(find.text("First Name"), findsOneWidget);
//       expect(find.text("Last Name"), findsOneWidget);
//       expect(find.text("Email"), findsOneWidget);
//       expect(find.text("Active"), findsOneWidget);
//       expect(find.text("Save"), findsOneWidget);
//     });
//
//     /// validate mock data
//     testWidgets("Render screen validate user data successful", (tester) async {
//       // Given:
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       //When:
//       await tester.pumpAndSettle();
//       //Then:
//       expect(find.text("test_login"), findsOneWidget);
//       expect(find.text("John"), findsOneWidget);
//       expect(find.text("Doe"), findsOneWidget);
//       expect(find.text("john.doe@example.com"), findsOneWidget);
//       // expect(find.text("true"), findsOneWidget);
//     });
//   });
//
//   group("EditUserScreen Bloc Test", () {
//     testWidgets("Given valid user data with AccessToken when Save Button clicked then update user Successfully", (tester) async {
//       await TestUtils().setupAuthentication();
//
//       // Given: render screen with valid user data
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       //When: wait screen is ready
//       await tester.pumpAndSettle(const Duration(seconds: 1));
//
//       // before click save button check button
//       expect(find.byType(ElevatedButton), findsOneWidget);
//       expect(find.text("Save"), findsOneWidget);
//
//       await tester.tap(find.text('Save'));
//       await tester.pumpAndSettle(const Duration(seconds: 5));
//
//       // after click save button check screen, dispose EditUserScreen and should be navigate to user list screen
//       expect(find.byType(EditUserScreen), findsNothing);
//     });
//
//     testWidgets("Given valid user data without AccessToken when Save Button clicked then update user fail (Unauthorized)", (tester) async {
//       // Given: render screen with valid user data
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       //When: wait screen is ready
//       await tester.pumpAndSettle();
//
//       // before click save button check button
//       expect(find.byType(ElevatedButton), findsOneWidget);
//       expect(find.text("Save"), findsOneWidget);
//
//       await tester.tap(find.text('Save'));
//       await tester.pumpAndSettle(const Duration(seconds: 5));
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       await tester.pumpAndSettle();
//
//       // after click save button check screen, without AccessToken should be stay in EditUserScreen
//       expect(find.byType(EditUserScreen), findsOneWidget);
//     });
//
//     testWidgets(
//         skip: true, // skip this test because of no-changes
//         "Given same user data (no-changes) without AccessToken when Save Button clicked then no-action", (tester) async {
//       // Given: render screen with valid user data
//       await tester.pumpWidget(getWidget(mockUserFullPayload));
//       //When: wait screen is ready
//       await tester.pumpAndSettle();
//
//       expect(find.byType(ElevatedButton), findsOneWidget);
//       expect(find.text("Save"), findsOneWidget);
//
//       await tester.tap(find.text('Save'));
//       await tester.pumpAndSettle(const Duration(seconds: 5));
//
//       // after click save button check screen, with same user data, EditUserScreen will not call bloc event then go back
//       expect(find.byType(EditUserScreen), findsNothing);
//     });
//   });
// }
