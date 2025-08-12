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

  static String m0(translate) =>
      "${Intl.select(translate, {'account': 'Account', 'userManagement': 'User Management', 'settings': 'Settings', 'logout': 'Logout', 'info': 'Info', 'language': 'Language', 'theme': 'Theme', 'new_user': 'New', 'list_user': 'List', 'other': 'Other'})}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "active": MessageLookupByLibrary.simpleMessage("Active"),
    "add_task": MessageLookupByLibrary.simpleMessage("Add Task"),
    "admin": MessageLookupByLibrary.simpleMessage("Admin"),
    "authorities": MessageLookupByLibrary.simpleMessage("Authorities"),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "change_password": MessageLookupByLibrary.simpleMessage("Change Password"),
    "chart_kpi_placeholder": MessageLookupByLibrary.simpleMessage("Chart / KPI Placeholder"),
    "create_user": MessageLookupByLibrary.simpleMessage("Create User"),
    "current_password": MessageLookupByLibrary.simpleMessage("Current Password"),
    "customers": MessageLookupByLibrary.simpleMessage("Customers"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "delete_confirmation": MessageLookupByLibrary.simpleMessage("Are you sure you want to delete?"),
    "delete_user": MessageLookupByLibrary.simpleMessage("Delete User"),
    "edit_user": MessageLookupByLibrary.simpleMessage("Edit User"),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "email_pattern": MessageLookupByLibrary.simpleMessage("Email must be a valid email address"),
    "email_send": MessageLookupByLibrary.simpleMessage("Send Email"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "first_name": MessageLookupByLibrary.simpleMessage("First Name"),
    "guest": MessageLookupByLibrary.simpleMessage("Guest"),
    "invalid_email": MessageLookupByLibrary.simpleMessage("Invalid email address"),
    "just_now": MessageLookupByLibrary.simpleMessage("just now"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "language_select": MessageLookupByLibrary.simpleMessage("Select Language"),
    "last_name": MessageLookupByLibrary.simpleMessage("Last Name"),
    "leads": MessageLookupByLibrary.simpleMessage("Leads"),
    "list": MessageLookupByLibrary.simpleMessage("List"),
    "list_user": MessageLookupByLibrary.simpleMessage("List User"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "login_button": MessageLookupByLibrary.simpleMessage("Login"),
    "login_password": MessageLookupByLibrary.simpleMessage("Password"),
    "login_user_name": MessageLookupByLibrary.simpleMessage("Username"),
    "login_with_email": MessageLookupByLibrary.simpleMessage("Login with Email"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "logout_sure": MessageLookupByLibrary.simpleMessage("Are you sure you want to logout?"),
    "max_length_10": MessageLookupByLibrary.simpleMessage("Field cannot be more than 10 characters long"),
    "max_length_100": MessageLookupByLibrary.simpleMessage("Field cannot be more than 100 characters long"),
    "max_length_1000": MessageLookupByLibrary.simpleMessage("Field cannot be more than 1000 characters long"),
    "max_length_20": MessageLookupByLibrary.simpleMessage("Field cannot be more than 20 characters long"),
    "max_length_250": MessageLookupByLibrary.simpleMessage("Field cannot be more than 250 characters long"),
    "max_length_4000": MessageLookupByLibrary.simpleMessage("Field cannot be more than 4000 characters long"),
    "max_length_50": MessageLookupByLibrary.simpleMessage("Field cannot be more than 50 characters long"),
    "max_length_500": MessageLookupByLibrary.simpleMessage("Field cannot be more than 500 characters long"),
    "min_length_2": MessageLookupByLibrary.simpleMessage("Field must be at least 2 characters long"),
    "min_length_3": MessageLookupByLibrary.simpleMessage("Field must be at least 3 characters long"),
    "min_length_4": MessageLookupByLibrary.simpleMessage("Field must be at least 4 characters long"),
    "min_length_5": MessageLookupByLibrary.simpleMessage("Field must be at least 5 characters long"),
    "more": MessageLookupByLibrary.simpleMessage("More"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "new_deal": MessageLookupByLibrary.simpleMessage("New Deal"),
    "new_lead": MessageLookupByLibrary.simpleMessage("New Lead"),
    "new_password": MessageLookupByLibrary.simpleMessage("New Password"),
    "new_user": MessageLookupByLibrary.simpleMessage("New User"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "no_changes_made": MessageLookupByLibrary.simpleMessage("No changes made"),
    "no_data": MessageLookupByLibrary.simpleMessage("No Data"),
    "only_numbers": MessageLookupByLibrary.simpleMessage("Only numbers are allowed"),
    "otp_code": MessageLookupByLibrary.simpleMessage("OTP Code"),
    "otp_length": MessageLookupByLibrary.simpleMessage("OTP must be 6 characters long"),
    "otp_sent_to": MessageLookupByLibrary.simpleMessage("OTP sent to"),
    "password_forgot": MessageLookupByLibrary.simpleMessage("Forgot Password"),
    "password_max_length": MessageLookupByLibrary.simpleMessage("Password cannot be more than 6 characters long"),
    "password_min_length": MessageLookupByLibrary.simpleMessage("Password must be at least 5 characters long"),
    "phone_number": MessageLookupByLibrary.simpleMessage("Phone Number"),
    "quick_actions": MessageLookupByLibrary.simpleMessage("Quick Actions"),
    "recent_activity": MessageLookupByLibrary.simpleMessage("Recent Activity"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "register": MessageLookupByLibrary.simpleMessage("Register"),
    "required_field": MessageLookupByLibrary.simpleMessage("Required Field"),
    "required_range": MessageLookupByLibrary.simpleMessage("Range is required"),
    "resend_otp_code": MessageLookupByLibrary.simpleMessage("Resend OTP Code"),
    "revenue": MessageLookupByLibrary.simpleMessage("Revenue"),
    "role": MessageLookupByLibrary.simpleMessage("Role"),
    "sample_activity_item": MessageLookupByLibrary.simpleMessage("Sample activity item"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "screen_size_error": MessageLookupByLibrary.simpleMessage("Screen size is too small."),
    "send_email_action": MessageLookupByLibrary.simpleMessage("Send Email"),
    "send_otp_code": MessageLookupByLibrary.simpleMessage("Send OTP Code"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "subtitle_context": MessageLookupByLibrary.simpleMessage("Subtitle / Context"),
    "success": MessageLookupByLibrary.simpleMessage("Success"),
    "taskName": MessageLookupByLibrary.simpleMessage("Task Name"),
    "taskPrice": MessageLookupByLibrary.simpleMessage("Task Price"),
    "taskSaveScreenTitle": MessageLookupByLibrary.simpleMessage("Task Save"),
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "translate_menu_title": m0,
    "turkish": MessageLookupByLibrary.simpleMessage("Turkish"),
    "unsaved_changes": MessageLookupByLibrary.simpleMessage(
      "You have unsaved changes. Are you sure you want to leave?",
    ),
    "verify_otp_code": MessageLookupByLibrary.simpleMessage("Verify OTP Code"),
    "view_user": MessageLookupByLibrary.simpleMessage("View User"),
    "warning": MessageLookupByLibrary.simpleMessage("Warning"),
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
  };
}
