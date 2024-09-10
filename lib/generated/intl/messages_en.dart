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
            'account': 'Account',
            'settings': 'Settings',
            'logout': 'Logout',
            'info': 'Info',
            'language': 'Language',
            'theme': 'Theme',
            'create': 'Create',
            'list': 'List/Edit',
            'other': 'Other',
          })}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "active": MessageLookupByLibrary.simpleMessage("Active"),
        "admin": MessageLookupByLibrary.simpleMessage("Admin"),
        "authorities": MessageLookupByLibrary.simpleMessage("Authorities"),
        "authorities_required":
            MessageLookupByLibrary.simpleMessage("Authorities is required"),
        "change_password":
            MessageLookupByLibrary.simpleMessage("Change Password"),
        "create_user": MessageLookupByLibrary.simpleMessage("Create User"),
        "description":
            MessageLookupByLibrary.simpleMessage("Flutter Bloc Advanced"),
        "edit_user": MessageLookupByLibrary.simpleMessage("Edit User"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
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
        "english": MessageLookupByLibrary.simpleMessage("English"),
        "first_name": MessageLookupByLibrary.simpleMessage("First Name"),
        "firstname_max_length": MessageLookupByLibrary.simpleMessage(
            "Firstname cannot be more than 20 characters long"),
        "firstname_min_length": MessageLookupByLibrary.simpleMessage(
            "Firstname must be at least 5 characters long"),
        "firstname_required":
            MessageLookupByLibrary.simpleMessage("Firstname is required"),
        "guest": MessageLookupByLibrary.simpleMessage("Guest"),
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
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
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
        "phone_number": MessageLookupByLibrary.simpleMessage("Phone Number"),
        "required_phone_type": MessageLookupByLibrary.simpleMessage(
            "Phone Type Required 5** *** ** ** "),
        "required_range":
            MessageLookupByLibrary.simpleMessage("Range is required"),
        "role": MessageLookupByLibrary.simpleMessage("Role"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "screen_size_error":
            MessageLookupByLibrary.simpleMessage("Screen size is too small."),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "translate_menu_title": m0,
        "turkish": MessageLookupByLibrary.simpleMessage("Turkish"),
        "username_max_length": MessageLookupByLibrary.simpleMessage(
            "Username cannot be more than 20 characters long"),
        "username_min_length": MessageLookupByLibrary.simpleMessage(
            "Username must be at least 5 characters long"),
        "username_regex_pattern": MessageLookupByLibrary.simpleMessage(
            "Username must be a valid email address"),
        "username_required":
            MessageLookupByLibrary.simpleMessage("Username is required"),
        "yes": MessageLookupByLibrary.simpleMessage("Yes")
      };
}
