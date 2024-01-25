import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_bloc_advance/presentation/common_blocs/authorities/authorities.dart';
import 'package:flutter_bloc_advance/presentation/screen/account/logout_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import '../configuration/environment.dart';
import '../configuration/routes.dart';
import '../data/repository/account_repository.dart';
import '../data/repository/authorities_repository.dart';
import '../data/repository/city_repository.dart';
import '../data/repository/corporation_maturity_repository.dart';
import '../data/repository/corporation_repository.dart';
import '../data/repository/customer_repository.dart';
import '../data/repository/district_repository.dart';
import '../data/repository/login_repository.dart';
import '../data/repository/maturity_calculate.dart';
import '../data/repository/menu_repository.dart';
import '../data/repository/offer_repository.dart';
import '../data/repository/refinery_repository.dart';
import '../data/repository/sales_people_repository.dart';
import '../data/repository/station_maturity_repository.dart';
import '../data/repository/station_repository.dart';
import '../data/repository/status_repository.dart';
import '../data/repository/user_repository.dart';
import '../generated/l10n.dart';
import '../presentation/common_blocs/account/account.dart';
import '../presentation/common_blocs/city/city_bloc.dart';
import '../presentation/common_blocs/district/district_bloc.dart';

import '../presentation/common_blocs/sales_people/sales_people_bloc.dart';
import '../presentation/common_blocs/status/status_bloc.dart';
import '../presentation/common_widgets/drawer/bloc/drawer_bloc.dart';
import '../presentation/screen/Maturity_calculate/bloc/maturity_calculate_bloc.dart';
import '../presentation/screen/Maturity_calculate/calculate_screen/screen.dart';
import '../presentation/screen/account/account_screen.dart';
import '../presentation/screen/change_password/bloc/change_password_bloc.dart';
import '../presentation/screen/change_password/change_password_screen.dart';
import '../presentation/screen/corporation/bloc/corporation_bloc.dart';
import '../presentation/screen/corporation/create/create_screen.dart';
import '../presentation/screen/corporation/list/list_screen.dart';
import '../presentation/screen/corporation_maturity/bloc/corporation_maturity_bloc.dart';
import '../presentation/screen/corporation_maturity/list/list_screen.dart';
import '../presentation/screen/customer/bloc/customer_bloc.dart';
import '../presentation/screen/forgot_password/bloc/forgot_password_bloc.dart';
import '../presentation/screen/forgot_password/forgot_password_screen.dart';
import '../presentation/screen/home/home_screen.dart';
import '../presentation/screen/login/bloc/login.dart';
import '../presentation/screen/login/login_screen.dart';
import '../presentation/screen/offer/bloc/offer/offer_bloc.dart';
import '../presentation/screen/offer/bloc/pdf/pdf_bloc.dart';
import '../presentation/screen/offer/bloc/price/price_bloc.dart';
import '../presentation/screen/offer/create/select_customer.dart';
import '../presentation/screen/offer/list/list_screen.dart';
import '../presentation/screen/refinery/bloc/refinery_bloc.dart';
import '../presentation/screen/refinery/create/create_screen.dart';
import '../presentation/screen/refinery/list/list_screen.dart';
import '../presentation/screen/settings/bloc/settings.dart';
import '../presentation/screen/settings/settings_screen.dart';
import '../presentation/screen/station/bloc/station_bloc.dart';
import '../presentation/screen/station/create/create_screen.dart';
import '../presentation/screen/station/list/list_screen.dart';
import '../presentation/screen/station_maturity/bloc/station_maturity_bloc.dart';
import '../presentation/screen/station_maturity/list/list_screen.dart';
import '../presentation/screen/user/bloc/user_bloc.dart';
import '../presentation/screen/user/create/create_user_screen.dart';
import '../presentation/screen/user/list/list_user_screen.dart';

/// Main application widget. This widget is the root of your application.
///
/// It is configured to provide a [ThemeData] based on the current
/// [AdaptiveThemeMode] and to provide a [MaterialApp] with the
/// [AdaptiveThemeMode] as the initial theme mode.
///

class App extends StatelessWidget {
  final String language;

  const App({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blueGrey,
      ),
      dark: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
      ),
      debugShowFloatingThemeButton: false,
      initial: AdaptiveThemeMode.light,
      builder: (light, dark) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<StatusBloc>(create: (_) => StatusBloc(statusRepository: StatusRepository())),
            BlocProvider<AuthoritiesBloc>(create: (_) => AuthoritiesBloc(authoritiesRepository: AuthoritiesRepository())),
            BlocProvider<SalesPersonBloc>(create: (_) => SalesPersonBloc(salesPersonRepository: SalesPersonRepository())),
            BlocProvider<UserBloc>(create: (_) => UserBloc(userRepository: UserRepository())),
            BlocProvider<CityBloc>(create: (_) => CityBloc(cityRepository: CityRepository())),
            BlocProvider<DistrictBloc>(create: (_) => DistrictBloc(districtRepository: DistrictRepository())),
            BlocProvider<StationBloc>(create: (_) => StationBloc(stationRepository: StationRepository())),
            BlocProvider<StationMaturityBloc>(create: (_) => StationMaturityBloc(stationMaturityRepository: StationMaturityRepository())),
            BlocProvider<CorporationMaturityBloc>(
                create: (_) => CorporationMaturityBloc(corporationMaturityRepository: CorporationMaturityRepository())),
            BlocProvider<DrawerBloc>(create: (_) => DrawerBloc(loginRepository: LoginRepository(), menuRepository: MenuRepository())),
            BlocProvider<CorporationBloc>(create: (_) => CorporationBloc(corporationRepository: CorporationRepository())),
            BlocProvider<RefineryBloc>(create: (_) => RefineryBloc(refineryRepository: RefineryRepository())),
            BlocProvider<CustomerBloc>(create: (_) => CustomerBloc(customerRepository: CustomerRepository())),
            BlocProvider<OfferBloc>(create: (_) => OfferBloc(offerRepository: OfferRepository())),
            BlocProvider<PdfBloc>(create: (_) => PdfBloc()),
            BlocProvider<PriceBloc>(create: (_) => PriceBloc()),
          ],
          child: GetMaterialApp(
            theme: light,
            darkTheme: dark,
            debugShowCheckedModeBanner: ProfileConstants.isDevelopment,
            debugShowMaterialGrid: false,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: Locale(language),
            routes: {
              ApplicationRoutes.home: (context) {
                return BlocProvider<AccountBloc>(
                    create: (context) => AccountBloc(accountRepository: AccountRepository())..add(AccountLoad()), child: HomeScreen());
              },
              ApplicationRoutes.account: (context) {
                return BlocProvider<AccountBloc>(
                    create: (context) => AccountBloc(accountRepository: AccountRepository())..add(AccountLoad()), child: AccountsScreen());
              },
              ApplicationRoutes.login: (context) {
                return BlocProvider<LoginBloc>(create: (context) => LoginBloc(loginRepository: LoginRepository()), child: LoginScreen());
              },
              ApplicationRoutes.settings: (context) {
                return BlocProvider<SettingsBloc>(
                    create: (context) => SettingsBloc(accountRepository: AccountRepository()), child: SettingsScreen());
              },
              ApplicationRoutes.forgotPassword: (context) {
                return BlocProvider<ForgotPasswordBloc>(
                    create: (context) => ForgotPasswordBloc(AccountRepository: AccountRepository()), child: ForgotPasswordScreen());
              },
              ApplicationRoutes.changePassword: (context) {
                return BlocProvider<ChangePasswordBloc>(
                    create: (context) => ChangePasswordBloc(AccountRepository: AccountRepository()), child: ChangePasswordScreen());
              },
              ApplicationRoutes.logout: (context) {
                return LogoutConfirmationDialog();
              },
              ApplicationRoutes.createUser: (context) {
                return BlocProvider<UserBloc>(create: (context) => UserBloc(userRepository: UserRepository()), child: CreateUserScreen());
              },
              ApplicationRoutes.listUsers: (context) {
                return BlocProvider<UserBloc>(create: (context) => UserBloc(userRepository: UserRepository()), child: ListUserScreen());
              },
              ApplicationRoutes.createRefinery: (context) {
                return BlocProvider<RefineryBloc>(
                    create: (context) => RefineryBloc(refineryRepository: RefineryRepository()), child: CreateRefineryScreen());
              },
              ApplicationRoutes.listRefineries: (context) {
                return BlocProvider<RefineryBloc>(
                    create: (context) => RefineryBloc(refineryRepository: RefineryRepository()), child: ListRefineriesScreen());
              },
              ApplicationRoutes.createCorporation: (context) {
                return BlocProvider<CorporationBloc>(
                    create: (context) => CorporationBloc(corporationRepository: CorporationRepository()), child: CreateCorporationScreen());
              },
              ApplicationRoutes.listCorporations: (context) {
                return BlocProvider<CorporationBloc>(
                    create: (context) => CorporationBloc(corporationRepository: CorporationRepository()), child: ListCorporationsScreen());
              },
              ApplicationRoutes.createStation: (context) {
                return BlocProvider<StationBloc>(
                    create: (context) => StationBloc(stationRepository: StationRepository()), child: CreateStationScreen());
              },
              ApplicationRoutes.listStations: (context) {
                return BlocProvider<StationBloc>(
                    create: (context) => StationBloc(stationRepository: StationRepository()), child: ListStationsScreen());
              },
              ApplicationRoutes.stationMaturity: (context) {
                return BlocProvider<StationMaturityBloc>(
                    create: (context) => StationMaturityBloc(stationMaturityRepository: StationMaturityRepository()),
                    child: ListStationMaturityScreen());
              },
              ApplicationRoutes.corporationMaturity: (context) {
                return BlocProvider<CorporationMaturityBloc>(
                    create: (context) => CorporationMaturityBloc(corporationMaturityRepository: CorporationMaturityRepository()),
                    child: ListCorporationMaturityScreen());
              },
              ApplicationRoutes.createOffer: (context) {
                return BlocProvider<OfferBloc>(
                    create: (context) => OfferBloc(offerRepository: OfferRepository()), child: CreateOfferWithSelectCustomerScreen());
              },
              ApplicationRoutes.listOffers: (context) {
                return BlocProvider<OfferBloc>(
                    create: (context) => OfferBloc(offerRepository: OfferRepository()), child: ListOffersScreen());
              },
              ApplicationRoutes.maturityCalculate: (context) {
                return BlocProvider<MaturityCalculateBloc>(
                    create: (context) => MaturityCalculateBloc(maturityCalculateRepository: MaturityCalculateRepository()), child: MaturityCalculateScreen());
              },
            },
          ),
        );
      },
    );
  }
}
