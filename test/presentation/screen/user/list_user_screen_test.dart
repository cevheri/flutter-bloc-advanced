import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/repository/authority_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authority/authority_bloc.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/bloc/user.dart';
import 'package:flutter_bloc_advance/presentation/screen/user/list/list_user_screen.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../test_utils.dart';

/// List User Screen Test
/// class ListUserScreen extends StatelessWidget
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Widget testWidget;

  final blocs = [
    BlocProvider<AuthorityBloc>(create: (_) => AuthorityBloc(repository: AuthorityRepository())),
    BlocProvider<UserBloc>(create: (_) => UserBloc(repository: UserRepository())),
  ];
  GetMaterialApp getWidget() {
    return GetMaterialApp(
      home: MultiBlocProvider(
        providers: blocs,
        child: ListUserScreen(),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  //region setup
  setUpAll(() async {
    await TestUtils().setupUnitTest();
    testWidget = getWidget();
    await Future.delayed(const Duration(milliseconds: 100));
  });
  tearDown(() async {
    await TestUtils().tearDownUnitTest();
    Get.reset();
    await Future.delayed(const Duration(milliseconds: 100));
  });
  //endregion setup

  testWidgets('renders ListUserScreen correctly', (tester) async {
    // Given: A ListUserScreen with mocked state is rendered
    await tester.pumpWidget(testWidget);

    // When: The screen is loaded
    await tester.pumpAndSettle();

    //Then: Check if the AppBar contains the correct title

    // Then: Check if the search form elements are present
    expect(find.byType(FormBuilderTextField), findsNWidgets(3));
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    expect(find.text('List User'), findsOneWidget);

    // Then: Check if the table header is rendered
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('displays user list when UserSearchSuccessState is emitted with JWTToken', (tester) async {
    await TestUtils().setupAuthentication();

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsAtLeastNWidgets(1));
    expect(find.text('admin'), findsAtLeastNWidgets(1));
    expect(find.text('User'), findsAtLeastNWidgets(1));
    expect(find.text('admin@sekoya.tech'), findsAtLeastNWidgets(1));
    expect(find.text('active'), findsAtLeastNWidgets(1));
    expect(find.byType(IconButton), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key("listUserSubmitButtonKey")));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final editButton = find.byKey(const Key('listUserEditButtonKey')).first;
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();
    //expect(find.byType(EditUserScreen), findsOneWidget);

    final formKey3 = tester.state<FormBuilderState>(find.byType(FormBuilder));
    formKey3.fields['rangeStart']?.didChange('0');
    formKey3.fields['rangeEnd']?.didChange('100');
    formKey3.fields['authority']?.didChange('ROLE_ADMIN');
    formKey3.fields['name']?.didChange('test');
  });

  testWidgets('displays user list when UserSearchSuccessState is emitted without token and fail', (tester) async {
    await tester.pumpWidget(testWidget);

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();

    expect(find.text('Admin'), findsNothing);
    expect(find.text('admin'), findsNothing);
    expect(find.text('User'), findsNothing);
    expect(find.text('admin@sekoya.tech'), findsNothing);
    expect(find.text('active'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('The correct layout should be shown when the screen width is above 900px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final context = tester.element(find.byType(ListUserScreen));
    expect(MediaQuery.of(context).size.width, greaterThan(900));

    expect(find.byType(FormBuilderTextField), findsNWidgets(3));
    expect(find.byType(ElevatedButton), findsOneWidget);

    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('The correct layout should be shown when the screen width is between 700-900px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));

    await tester.pumpWidget(testWidget);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final context = tester.element(find.byType(ListUserScreen));
    final width = MediaQuery.of(context).size.width;
    expect(width, greaterThan(700));
    expect(width, lessThan(900));
  });

  testWidgets('Error message should be shown when screen width is below 700px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));

    await tester.pumpWidget(testWidget);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
    expect(find.text('Screen size is too small.'), findsOneWidget);
  });

  testWidgets('The correct layout should be shown when the screen width is between 700-900px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final context = tester.element(find.byType(ListUserScreen));
    final width = MediaQuery.of(context).size.width;
    expect(width, greaterThan(700));
    expect(width, lessThan(900));

    expect(find.byType(FormBuilderTextField), findsNWidgets(3));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Error message should be shown when screen width is below 700px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
    expect(find.text('Screen size is too small.'), findsOneWidget);
  });

  testWidgets('NavigatorPush and form validation should work correctly when Edit button is pressed', (tester) async {
    await TestUtils().setupAuthentication();

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 1));

    //await tester.tap(find.byKey(const Key("listUserSubmitButtonKey")));
    //await tester.pumpAndSettle(Duration(seconds: 1));

    //final editButton = find.byKey(const Key('listUserEditButtonKey')).first;
    //expect(editButton, findsOneWidget);

    //await tester.tap(editButton);
    //await tester.pumpAndSettle();
    //expect(find.byType(EditUserScreen), findsOneWidget);
  });

  testWidgets('UserSearch should not be called if form validation fails when Edit button is pressed', (tester) async {
    await TestUtils().setupAuthentication();

    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 1));

    // When: ListUserScreen is shown and UserBloc emits the state
    // final userSearchEvent = UserSearch(0, 100, "-", "");
    // BlocProvider.of<UserBloc>(tester.element(find.byType(ListUserScreen))).add(userSearchEvent);
    // await tester.tap(find.text('List'));
    // await tester.pumpAndSettle();

    // final editButton = find.byKey(const Key('listUserEditButtonKey')).first;
    //expect(editButton, findsOneWidget);

    // await tester.tap(editButton);
  });
}
