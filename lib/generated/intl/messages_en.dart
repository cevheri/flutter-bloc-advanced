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
            'customer': 'Customers',
            'tasks': 'Tasks',
            'account': 'Account',
            'settings': 'Settings',
            'dashboard': 'Dashboard',
            'reports': 'Reports',
            'logout': 'Logout',
            'info': 'Info',
            'language': 'Language',
            'theme': 'Theme',
            'createOffer': 'Create Offer',
            'editOffer': 'List/Edit',
            'other': 'Other',
          })}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountScreenTitle": MessageLookupByLibrary.simpleMessage("Account"),
        "drawerLogoutTitle": MessageLookupByLibrary.simpleMessage("Logout"),
        "drawerMenuHome": MessageLookupByLibrary.simpleMessage("Home"),
        "drawerSettingsTitle": MessageLookupByLibrary.simpleMessage("Settings"),
        "drawerTasks": MessageLookupByLibrary.simpleMessage("Tasks"),
        "english": MessageLookupByLibrary.simpleMessage("English"),
        "firstName": MessageLookupByLibrary.simpleMessage("First Name"),
        "homeScreenTitle": MessageLookupByLibrary.simpleMessage("Home"),
        "language_select":
            MessageLookupByLibrary.simpleMessage("Select Language"),
        "locale": MessageLookupByLibrary.simpleMessage("en"),
        "loginScreenTitle": MessageLookupByLibrary.simpleMessage("Login"),
        "pageSettingsTitle": MessageLookupByLibrary.simpleMessage("Settings"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "settingsScreenTitle": MessageLookupByLibrary.simpleMessage("Settings"),
        "taskName": MessageLookupByLibrary.simpleMessage("Task Name"),
        "taskPrice": MessageLookupByLibrary.simpleMessage("Task Price"),
        "taskSaveScreenTitle":
            MessageLookupByLibrary.simpleMessage("Save or Update Task"),
        "tasksScreenTitle": MessageLookupByLibrary.simpleMessage("Tasks"),
        "title": MessageLookupByLibrary.simpleMessage("Task Management App"),
        "translate_menu_title": m0,
        "turkish": MessageLookupByLibrary.simpleMessage("Turkish")
      };
}
