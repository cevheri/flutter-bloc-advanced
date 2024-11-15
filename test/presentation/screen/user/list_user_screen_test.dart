import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/environment.dart';
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

import '../../../init.dart';

/// List User Screen Test
/// class ListUserScreen extends StatelessWidget
void main() {
  setUpAll(() {
    // Set the environment to test for working with mock-json data on the API
    initBlocDependencies();
  });

  final blocs = [
    BlocProvider<AuthoritiesBloc>(create: (_) => AuthoritiesBloc(authoritiesRepository: AuthoritiesRepository())),
    BlocProvider<AccountBloc>(create: (_) => AccountBloc(accountRepository: AccountRepository())),
    BlocProvider<UserBloc>(create: (_) => UserBloc(userRepository: UserRepository())),
    BlocProvider<CityBloc>(create: (_) => CityBloc(cityRepository: CityRepository())),
    BlocProvider<DistrictBloc>(create: (_) => DistrictBloc(districtRepository: DistrictRepository())),
    BlocProvider<DrawerBloc>(create: (_) => DrawerBloc(loginRepository: LoginRepository(), menuRepository: MenuRepository())),
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

  // testWidgets('FormBuilderDropdown is displayed when state is AuthoritiesLoadSuccessState', (WidgetTester tester) async {
  //   final mockAuthoritiesBloc = MockAuthoritiesBloc();
  //
  //   whenListen(
  //     mockAuthoritiesBloc,
  //     Stream.fromIterable([AuthoritiesLoadSuccessState(roleList: ['ROLE_USER', 'ROLE_ADMIN'])]),
  //     initialState: AuthoritiesInitial(),
  //   );
  //
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: BlocProvider<AuthoritiesBloc>(
  //         create: (context) => mockAuthoritiesBloc,
  //         child: ListUserScreen(),
  //       ),
  //     ),
  //   );
  //
  //   await tester.pumpAndSettle();
  //
  //   expect(find.byType(FormBuilderDropdown), findsOneWidget);
  // });


}
