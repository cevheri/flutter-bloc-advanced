// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(translate) => "${Intl.select(translate, {
            'station': 'Stations',
            'maturityCalculate': 'Maturity Calculated',
            'stationMaturity': 'Station Maturity',
            'corporation': 'Corporations',
            'corporationMaturity': 'Corporation Maturity',
            'refinery': 'Refineries',
            'offer': 'Offers',
            'customer': 'Customers',
            'salesPerson': 'Sales Person',
            'account': 'Account',
            'settings': 'Settings',
            'dashboard': 'Dashboard',
            'reports': 'Reports',
            'logout': 'Logout',
            'info': 'Info',
            'language': 'Language',
            'theme': 'Theme',
            'create': 'Create',
            'list': 'List/Edit',
            'other': 'Other',
          })}";

  static String m1(translate) => "${Intl.select(translate, {
            'selected': 'All',
            'CALCULATED': 'Hesaplanan Teklif',
            'APPROVAL_IN_PROGRESS': 'Teklif Onay',
            'TO_BE_ORDERED': 'Teklif onaylandı',
            'APPROVAL_REJECTED': 'Teklif reddedildi',
            'IN_NEGOTIATION': 'Güncel teklif müşteriye önerildi',
            'ACCEPTED': 'Güncel teklifi müşteri kabul etti',
            'RESCINDED': 'Güncel teklifi müşteri red etti',
            'SHIPPED': 'Tamamlandı',
            'CANCELLED': 'Teklif geri çekildi ve iptal edildi',
            'DRAFT': 'Kaydet',
            'APPROVED': 'Teklif müşteriye gönderilmeye hazır',
            'ORDERED': 'Sipariş hazırlandı',
            'other': 'Diğer',
          })}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "active": MessageLookupByLibrary.simpleMessage("Active"),
        "address": MessageLookupByLibrary.simpleMessage("Address"),
        "admin": MessageLookupByLibrary.simpleMessage("Admin"),
        "approved_status": MessageLookupByLibrary.simpleMessage("Approved"),
        "authorities": MessageLookupByLibrary.simpleMessage("Authorities"),
        "authorities_required":
            MessageLookupByLibrary.simpleMessage("Authorities is required"),
        "birim": MessageLookupByLibrary.simpleMessage("birim"),
        "birim_numeric":
            MessageLookupByLibrary.simpleMessage("birim must be a valid"),
        "birim_required":
            MessageLookupByLibrary.simpleMessage("birim is required"),
        "calculate": MessageLookupByLibrary.simpleMessage("Calculate"),
        "calculated_maturity_screen":
            MessageLookupByLibrary.simpleMessage("Calculated Maturity"),
        "calculated_status": MessageLookupByLibrary.simpleMessage("Calculated"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cancelled_status": MessageLookupByLibrary.simpleMessage("Cancelled"),
        "cari_kod": MessageLookupByLibrary.simpleMessage("Account Code"),
        "change": MessageLookupByLibrary.simpleMessage("Change Password"),
        "change_nothing":
            MessageLookupByLibrary.simpleMessage("Nothing changed"),
        "change_password":
            MessageLookupByLibrary.simpleMessage("Change Password"),
        "cities": MessageLookupByLibrary.simpleMessage("Cities"),
        "city": MessageLookupByLibrary.simpleMessage("City"),
        "city_required":
            MessageLookupByLibrary.simpleMessage("City is required"),
        "code": MessageLookupByLibrary.simpleMessage("Code"),
        "company_name": MessageLookupByLibrary.simpleMessage("Company Name"),
        "completed_status": MessageLookupByLibrary.simpleMessage("Completed"),
        "confirm": MessageLookupByLibrary.simpleMessage("Passwords must match"),
        "confirm_new":
            MessageLookupByLibrary.simpleMessage("Confirm New Password"),
        "confirmation_status":
            MessageLookupByLibrary.simpleMessage("Confirmation Offers"),
        "corporation": MessageLookupByLibrary.simpleMessage("Corporation"),
        "corporation_required":
            MessageLookupByLibrary.simpleMessage("Corporation is required"),
        "corporations": MessageLookupByLibrary.simpleMessage("Corporations"),
        "cost": MessageLookupByLibrary.simpleMessage("Cost"),
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createNewOffer":
            MessageLookupByLibrary.simpleMessage("Create New Offer"),
        "create_corporation":
            MessageLookupByLibrary.simpleMessage("Create Corporation"),
        "create_corporation_maturity":
            MessageLookupByLibrary.simpleMessage("Create Corporation Maturity"),
        "create_offer": MessageLookupByLibrary.simpleMessage("Create Offer"),
        "create_record_error": MessageLookupByLibrary.simpleMessage(
            "Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!"),
        "create_refinery":
            MessageLookupByLibrary.simpleMessage("Create Refinery"),
        "create_station":
            MessageLookupByLibrary.simpleMessage("Create Station"),
        "create_station_maturity":
            MessageLookupByLibrary.simpleMessage("Create Station Maturity"),
        "create_user": MessageLookupByLibrary.simpleMessage("Create User"),
        "credit": MessageLookupByLibrary.simpleMessage("Credit"),
        "credit_card": MessageLookupByLibrary.simpleMessage("Credit Card"),
        "currentPassword":
            MessageLookupByLibrary.simpleMessage("Current Password"),
        "customer": MessageLookupByLibrary.simpleMessage("Customer"),
        "customers": MessageLookupByLibrary.simpleMessage("Customers"),
        "daily": MessageLookupByLibrary.simpleMessage("Daily"),
        "darkLight": MessageLookupByLibrary.simpleMessage("Dark/Light Mode"),
        "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
        "date": MessageLookupByLibrary.simpleMessage("Date"),
        "day": MessageLookupByLibrary.simpleMessage("Day"),
        "debt": MessageLookupByLibrary.simpleMessage("Debt"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "delete_confirmation": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete?"),
        "description": MessageLookupByLibrary.simpleMessage("CRM"),
        "description_max_length": MessageLookupByLibrary.simpleMessage(
            "Description cannot be more than 20 characters long"),
        "description_min_length": MessageLookupByLibrary.simpleMessage(
            "Description must be at least 5 characters long"),
        "description_offer":
            MessageLookupByLibrary.simpleMessage("Description"),
        "description_regex_pattern":
            MessageLookupByLibrary.simpleMessage("Description must be a valid"),
        "description_required":
            MessageLookupByLibrary.simpleMessage("Description is required"),
        "destination_address":
            MessageLookupByLibrary.simpleMessage("Destination Address"),
        "destination_city":
            MessageLookupByLibrary.simpleMessage("Destination City"),
        "destination_city_required": MessageLookupByLibrary.simpleMessage(
            "Destination City is required"),
        "destination_district":
            MessageLookupByLibrary.simpleMessage("Destination District"),
        "detail": MessageLookupByLibrary.simpleMessage("Detail"),
        "district": MessageLookupByLibrary.simpleMessage("District"),
        "districts": MessageLookupByLibrary.simpleMessage("Districts"),
        "document": MessageLookupByLibrary.simpleMessage("Document"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "edit_corporation":
            MessageLookupByLibrary.simpleMessage("Edit Corporation"),
        "edit_corporation_maturity":
            MessageLookupByLibrary.simpleMessage("Edit Corporation Maturity"),
        "edit_offer": MessageLookupByLibrary.simpleMessage("Edit Offer"),
        "edit_refinery": MessageLookupByLibrary.simpleMessage("Edit Refinery"),
        "edit_station": MessageLookupByLibrary.simpleMessage("Edit Station"),
        "edit_station_maturity":
            MessageLookupByLibrary.simpleMessage("Edit Station Maturity"),
        "edit_user": MessageLookupByLibrary.simpleMessage("Edit User"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "email_error":
            MessageLookupByLibrary.simpleMessage("Email address not found"),
        "email_pattern": MessageLookupByLibrary.simpleMessage(
            "Email must be a valid email address"),
        "email_required":
            MessageLookupByLibrary.simpleMessage("Email is required"),
        "email_reset_password_error":
            MessageLookupByLibrary.simpleMessage("Email address not found"),
        "email_reset_password_sending": MessageLookupByLibrary.simpleMessage(
            "Sending email to reset password..."),
        "email_reset_password_success":
            MessageLookupByLibrary.simpleMessage("Email sent successfully"),
        "email_send": MessageLookupByLibrary.simpleMessage("Send Email"),
        "email_success":
            MessageLookupByLibrary.simpleMessage("Email sent successfully"),
        "empty": MessageLookupByLibrary.simpleMessage(
            "Password cannot be left blank"),
        "english": MessageLookupByLibrary.simpleMessage("English"),
        "error":
            MessageLookupByLibrary.simpleMessage("Email address not found"),
        "exit": MessageLookupByLibrary.simpleMessage("Exit"),
        "find": MessageLookupByLibrary.simpleMessage(" Find "),
        "first_name": MessageLookupByLibrary.simpleMessage("First Name"),
        "firstname_max_length": MessageLookupByLibrary.simpleMessage(
            "Firstname cannot be more than 20 characters long"),
        "firstname_min_length": MessageLookupByLibrary.simpleMessage(
            "Firstname must be at least 5 characters long"),
        "firstname_required":
            MessageLookupByLibrary.simpleMessage("Firstname is required"),
        "forgot": MessageLookupByLibrary.simpleMessage("Forgot Password"),
        "global": MessageLookupByLibrary.simpleMessage("CRM"),
        "home": MessageLookupByLibrary.simpleMessage("Home"),
        "home_page": MessageLookupByLibrary.simpleMessage("Home Page"),
        "http_400": MessageLookupByLibrary.simpleMessage("Bad Request"),
        "http_401": MessageLookupByLibrary.simpleMessage("Unauthorized"),
        "http_402": MessageLookupByLibrary.simpleMessage("Payment Required"),
        "http_403": MessageLookupByLibrary.simpleMessage("Forbidden"),
        "http_404": MessageLookupByLibrary.simpleMessage("Not Found"),
        "http_405": MessageLookupByLibrary.simpleMessage("Method Not Allowed"),
        "http_406": MessageLookupByLibrary.simpleMessage("Not Acceptable"),
        "http_407": MessageLookupByLibrary.simpleMessage(
            "Proxy Authentication Required"),
        "http_408": MessageLookupByLibrary.simpleMessage("Request Timeout"),
        "http_409": MessageLookupByLibrary.simpleMessage("Conflict"),
        "http_410": MessageLookupByLibrary.simpleMessage("Gone"),
        "http_411": MessageLookupByLibrary.simpleMessage("Length Required"),
        "http_412": MessageLookupByLibrary.simpleMessage("Precondition Failed"),
        "http_413": MessageLookupByLibrary.simpleMessage("Payload Too Large"),
        "http_414": MessageLookupByLibrary.simpleMessage("URI Too Long"),
        "http_415":
            MessageLookupByLibrary.simpleMessage("Unsupported Media Type"),
        "http_416":
            MessageLookupByLibrary.simpleMessage("Range Not Satisfiable"),
        "http_417": MessageLookupByLibrary.simpleMessage("Expectation Failed"),
        "http_422":
            MessageLookupByLibrary.simpleMessage("Unprocessable Entity"),
        "http_425": MessageLookupByLibrary.simpleMessage("Too Early"),
        "http_426": MessageLookupByLibrary.simpleMessage("Upgrade Required"),
        "http_428":
            MessageLookupByLibrary.simpleMessage("Precondition Required"),
        "http_429": MessageLookupByLibrary.simpleMessage("Too Many Requests"),
        "http_431": MessageLookupByLibrary.simpleMessage(
            "Request Header Fields Too Large"),
        "http_451": MessageLookupByLibrary.simpleMessage(
            "Unavailable For Legal Reasons"),
        "http_500":
            MessageLookupByLibrary.simpleMessage("Internal Server Error"),
        "id": MessageLookupByLibrary.simpleMessage("ID"),
        "increase": MessageLookupByLibrary.simpleMessage("Increase"),
        "increase_unit_price":
            MessageLookupByLibrary.simpleMessage("Increase Price"),
        "indicator": MessageLookupByLibrary.simpleMessage("Loading..."),
        "language_select":
            MessageLookupByLibrary.simpleMessage("Select Language"),
        "last_name": MessageLookupByLibrary.simpleMessage("Last Name"),
        "lastname_max_length": MessageLookupByLibrary.simpleMessage(
            "Lastname cannot be more than 20 characters long"),
        "lastname_min_length": MessageLookupByLibrary.simpleMessage(
            "Lastname must be at least 5 characters long"),
        "lastname_required":
            MessageLookupByLibrary.simpleMessage("Lastname is required"),
        "list": MessageLookupByLibrary.simpleMessage("List"),
        "listOffer": MessageLookupByLibrary.simpleMessage("List Offer"),
        "list_corporation":
            MessageLookupByLibrary.simpleMessage("List Corporation"),
        "list_offer": MessageLookupByLibrary.simpleMessage("List Offer"),
        "list_refinery": MessageLookupByLibrary.simpleMessage("List Refinery"),
        "list_station": MessageLookupByLibrary.simpleMessage("List Station"),
        "list_user": MessageLookupByLibrary.simpleMessage("List User"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
        "logging_in": MessageLookupByLibrary.simpleMessage("Logging in..."),
        "login": MessageLookupByLibrary.simpleMessage("Login"),
        "login_button": MessageLookupByLibrary.simpleMessage("Login"),
        "login_error": MessageLookupByLibrary.simpleMessage("Login failed."),
        "login_password": MessageLookupByLibrary.simpleMessage("Password"),
        "login_user_name": MessageLookupByLibrary.simpleMessage("Username"),
        "logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "logout_sure": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to logout?"),
        "maturity": MessageLookupByLibrary.simpleMessage("Maturity"),
        "maturity_type": MessageLookupByLibrary.simpleMessage("Maturity Type"),
        "maturity_types":
            MessageLookupByLibrary.simpleMessage("Maturity Types"),
        "menu": MessageLookupByLibrary.simpleMessage("Menu"),
        "messages": MessageLookupByLibrary.simpleMessage(
            "Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "name_max_length": MessageLookupByLibrary.simpleMessage(
            "Name cannot be more than 20 characters long"),
        "name_min_length": MessageLookupByLibrary.simpleMessage(
            "Name must be at least 5 characters long"),
        "name_regex_pattern":
            MessageLookupByLibrary.simpleMessage("Name must be a valid"),
        "name_required":
            MessageLookupByLibrary.simpleMessage("Name is required"),
        "new_increase": MessageLookupByLibrary.simpleMessage("New Increase"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "not_match":
            MessageLookupByLibrary.simpleMessage("Passwords do not match"),
        "offer_form": MessageLookupByLibrary.simpleMessage("Offer Form"),
        "offers": MessageLookupByLibrary.simpleMessage("Offers"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "password_forgot":
            MessageLookupByLibrary.simpleMessage("Forgot Password"),
        "password_max_length": MessageLookupByLibrary.simpleMessage(
            "Password cannot be more than 6 characters long"),
        "password_min_length": MessageLookupByLibrary.simpleMessage(
            "Password must be at least 5 characters long"),
        "password_new": MessageLookupByLibrary.simpleMessage("New Password"),
        "password_required":
            MessageLookupByLibrary.simpleMessage("Password is required"),
        "password_success": MessageLookupByLibrary.simpleMessage(
            "Password changed successfully"),
        "phone": MessageLookupByLibrary.simpleMessage("Phone"),
        "phone_number": MessageLookupByLibrary.simpleMessage("Phone Number"),
        "plasiyer": MessageLookupByLibrary.simpleMessage("Plasiyer"),
        "price": MessageLookupByLibrary.simpleMessage("Price"),
        "price_empty":
            MessageLookupByLibrary.simpleMessage("Price cannot be empty"),
        "price_max_length": MessageLookupByLibrary.simpleMessage(
            "Price cannot be more than 10 characters long"),
        "price_min_length": MessageLookupByLibrary.simpleMessage(
            "Price must be at least 1 characters long"),
        "price_regex_pattern":
            MessageLookupByLibrary.simpleMessage("Price must be a valid"),
        "price_required":
            MessageLookupByLibrary.simpleMessage("Price is required"),
        "price_with_vat":
            MessageLookupByLibrary.simpleMessage("With Wat Price"),
        "price_with_vat_empty": MessageLookupByLibrary.simpleMessage(
            "With Wat Price cannot be empty"),
        "price_with_vat_max_length": MessageLookupByLibrary.simpleMessage(
            "With Wat Price cannot be more than 10 characters long"),
        "price_with_vat_min_length": MessageLookupByLibrary.simpleMessage(
            "With Wat Price must be at least 1 characters long"),
        "price_with_vat_regex_pattern": MessageLookupByLibrary.simpleMessage(
            "With Wat Price must be a valid"),
        "price_with_vat_required":
            MessageLookupByLibrary.simpleMessage("With Wat Price is required"),
        "range": MessageLookupByLibrary.simpleMessage("Range"),
        "rate": MessageLookupByLibrary.simpleMessage("Rate"),
        "refineries": MessageLookupByLibrary.simpleMessage("Refineries"),
        "refineries_description":
            MessageLookupByLibrary.simpleMessage("Refineries Description"),
        "refinery": MessageLookupByLibrary.simpleMessage("Refinery"),
        "refinery_required":
            MessageLookupByLibrary.simpleMessage("Refinery is required"),
        "rejected_status": MessageLookupByLibrary.simpleMessage("Rejected"),
        "reports": MessageLookupByLibrary.simpleMessage("Reports"),
        "required_cost":
            MessageLookupByLibrary.simpleMessage("Cost is required"),
        "required_maturity":
            MessageLookupByLibrary.simpleMessage("Maturity is required"),
        "required_phone_type": MessageLookupByLibrary.simpleMessage(
            "Phone Type Required 5** *** ** ** "),
        "required_range":
            MessageLookupByLibrary.simpleMessage("Range is required"),
        "required_rate":
            MessageLookupByLibrary.simpleMessage("Rate is required"),
        "required_salesPerson":
            MessageLookupByLibrary.simpleMessage("Sales Person is required"),
        "reset": MessageLookupByLibrary.simpleMessage(
            "Reset Email Address Password"),
        "role": MessageLookupByLibrary.simpleMessage("Role"),
        "salesPerson": MessageLookupByLibrary.simpleMessage("Sales Person"),
        "sales_person_code":
            MessageLookupByLibrary.simpleMessage("Sales Person Code"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "screen_size_error":
            MessageLookupByLibrary.simpleMessage("Screen size is too small."),
        "select": MessageLookupByLibrary.simpleMessage("Select"),
        "select_customer":
            MessageLookupByLibrary.simpleMessage("Select Customer"),
        "send": MessageLookupByLibrary.simpleMessage("Send"),
        "send_offer": MessageLookupByLibrary.simpleMessage("Send Offer"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "station": MessageLookupByLibrary.simpleMessage("Station"),
        "station_rate": MessageLookupByLibrary.simpleMessage("Station Rate"),
        "station_required":
            MessageLookupByLibrary.simpleMessage("Station is required"),
        "stations": MessageLookupByLibrary.simpleMessage("Stations"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "success":
            MessageLookupByLibrary.simpleMessage("Password reset successfully"),
        "tax_number": MessageLookupByLibrary.simpleMessage("Tax Number"),
        "tax_office": MessageLookupByLibrary.simpleMessage("Tax Office"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "title": MessageLookupByLibrary.simpleMessage("Home Page"),
        "todoList": MessageLookupByLibrary.simpleMessage("Todo List"),
        "total_price": MessageLookupByLibrary.simpleMessage("Total Price"),
        "translate_menu_title": m0,
        "translate_status_title": m1,
        "transport_cost":
            MessageLookupByLibrary.simpleMessage("Transport Cost TL"),
        "transport_cost_numeric": MessageLookupByLibrary.simpleMessage(
            "Transport Cost must be a valid"),
        "transport_cost_required":
            MessageLookupByLibrary.simpleMessage("Transport Cost is required"),
        "transport_cost_tl": MessageLookupByLibrary.simpleMessage("Transport"),
        "transport_date":
            MessageLookupByLibrary.simpleMessage("Transport Date"),
        "transport_date_required":
            MessageLookupByLibrary.simpleMessage("Transport Date is required"),
        "transport_distance":
            MessageLookupByLibrary.simpleMessage("Transport Distance Km"),
        "transport_distance_numeric": MessageLookupByLibrary.simpleMessage(
            "Transport Distance must be a valid"),
        "transport_distance_required": MessageLookupByLibrary.simpleMessage(
            "Transport Distance is required"),
        "turkish": MessageLookupByLibrary.simpleMessage("Turkish"),
        "unit_price": MessageLookupByLibrary.simpleMessage("Unit Price"),
        "unit_price_update":
            MessageLookupByLibrary.simpleMessage("Last Price Update"),
        "update": MessageLookupByLibrary.simpleMessage("Update"),
        "update_description":
            MessageLookupByLibrary.simpleMessage("Update Description"),
        "username_max_length": MessageLookupByLibrary.simpleMessage(
            "Username cannot be more than 20 characters long"),
        "username_min_length": MessageLookupByLibrary.simpleMessage(
            "Username must be at least 5 characters long"),
        "username_regex_pattern": MessageLookupByLibrary.simpleMessage(
            "Username must be a valid email address"),
        "username_required":
            MessageLookupByLibrary.simpleMessage("Username is required"),
        "users": MessageLookupByLibrary.simpleMessage("Users"),
        "vat_no": MessageLookupByLibrary.simpleMessage("Vat No"),
        "weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
        "welcome": MessageLookupByLibrary.simpleMessage("Welcome"),
        "yes": MessageLookupByLibrary.simpleMessage("Yes")
      };
}
