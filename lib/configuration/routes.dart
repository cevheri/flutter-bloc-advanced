/// Routes for the application
///
/// This class contains all the routes used in the application.
class ApplicationRoutes {
  static final home = '/';
  static final login = '/login';
  static final info = '/info';
  static final logout = '/logout';
  static final register = '/register';
  static final settings = '/settings';
  //static final language = '/settings/language';
  static final forgotPassword = '/forgot-password';
  static final changePassword = '/settings/change-password';
  static final account = '/account';
  static final createUser = '/admin/new-user';
  static final listUsers = '/admin/list-users';
  static final customer = '/customer';
  static final offers = '/offers';
  static final offerings = '/offerings';
  static final offeringsDetail = '/offerings/:id';
  static final offeringNew = '/offerings/new';
  static final offeringEdit = '/offerings/:id/edit';
  static final offeringDelete = '/offerings/:id/delete';
  static final offeringComplete = '/offerings/:id/complete';
  static final station = '/station';
  static final createStation = '/station/new-station';
  static final listStations = '/station/list-stations';
  static final stationMaturity = '/station-maturity';
  static final corporationMaturity = '/corporation-maturity';
  static final refinery = '/refinery';
  static final createRefinery = '/refinery/new-refinery';
  static final listRefineries = '/refinery/list-refineries';
  static final corporation = '/corporation';
  static final createCorporation = '/corporation/new-corporation';
  static final listCorporations = '/corporation/list-corporations';
  static final offer = '/offer';
  static final createOffer = '/offer/new-offer';
  static final listOffers = '/offer/list-offers';
  static final maturityCalculate = '/maturity-calculate';
}
