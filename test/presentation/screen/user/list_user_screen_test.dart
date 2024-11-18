import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/data/repository/account_repository.dart';
import 'package:flutter_bloc_advance/data/repository/authorities_repository.dart';
import 'package:flutter_bloc_advance/data/repository/city_repository.dart';
import 'package:flutter_bloc_advance/data/repository/district_repository.dart';
import 'package:flutter_bloc_advance/data/repository/login_repository.dart';
import 'package:flutter_bloc_advance/data/repository/menu_repository.dart';
import 'package:flutter_bloc_advance/data/repository/user_repository.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/account/account.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authorities/authorities_bloc.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/city/city.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/district/district.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/drawer/drawer_bloc/drawer.dart';
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
  /// init setup
  setUp(() {
    TestUtils.initBlocDependencies();
  });

  final blocs = [
    BlocProvider<AuthoritiesBloc>(create: (_) => AuthoritiesBloc(authoritiesRepository: AuthoritiesRepository())),
    BlocProvider<UserBloc>(create: (_) => UserBloc(userRepository: UserRepository())),
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

  testWidgets('renders ListUserScreen correctly', (tester) async {
    TestUtils.initWidgetDependencies();

    // Given: A ListUserScreen with mocked state is rendered
    await tester.pumpWidget(getWidget());

    // When: The screen is loaded
    await tester.pumpAndSettle();

    //Then: Check if the AppBar contains the correct title

    // Then: Check if the search form elements are present
    expect(find.byType(FormBuilderTextField), findsNWidgets(3));
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('List'), findsOneWidget);

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
    TestUtils.initWidgetDependenciesWithToken();
    await tester.pumpAndSettle();

    // Given: A mock UserSearchSuccessState with a list of users
    await tester.pumpWidget(getWidget());

    // When: ListUserScreen is shown and UserBloc emits the state
    // final userSearchEvent = UserSearch(0, 100, "-", "");
    // BlocProvider.of<UserBloc>(tester.element(find.byType(ListUserScreen))).add(userSearchEvent);
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();

    // Then: Verify that the list is displayed with correct data
    expect(find.text('Admin'), findsAtLeastNWidgets(1));
    expect(find.text('admin'), findsAtLeastNWidgets(1));
    expect(find.text('User'), findsAtLeastNWidgets(1));
    expect(find.text('admin@sekoya.tech'), findsAtLeastNWidgets(1));
    expect(find.text('active'), findsAtLeastNWidgets(1));
    expect(find.byType(IconButton), findsAtLeastNWidgets(1));
  });

  testWidgets('displays user list when UserSearchSuccessState is emitted without token and fail', (tester) async {
    // Given: A mock UserSearchSuccessState with a list of users

    await tester.pumpWidget(getWidget());
    //final bloc = BlocProvider.of<UserBloc>(tester.element(find.byType(ListUserScreen)));
    // When: ListUserScreen is shown and UserBloc emits the state
    // final userSearchEvent = UserSearch(0, 100, "-", "");
    // BlocProvider.of<UserBloc>(tester.element(find.byType(ListUserScreen))).add(userSearchEvent);
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();

    // Then handle the Unauthorized error with state
    //TODO list-user-test: when run all test bloc is a initial state, when run only this test bloc is a failure state
    //expect(bloc.state, isA<UserFindInitialState>());
    //expect(bloc.state, isA<UserSearchFailureState>());

    // Then: Verify that the list is not displayed
    expect(find.text('Admin'), findsNothing);
    expect(find.text('admin'), findsNothing);
    expect(find.text('User'), findsNothing);
    expect(find.text('admin@sekoya.tech'), findsNothing);
    expect(find.text('active'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });
}
