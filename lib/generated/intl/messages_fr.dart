// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
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
  String get localeName => 'fr';

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
        "accountScreenTitle": MessageLookupByLibrary.simpleMessage("Compte"),
        "drawerLogoutTitle":
            MessageLookupByLibrary.simpleMessage("Déconnexion"),
        "drawerMenuHome": MessageLookupByLibrary.simpleMessage("Accueil"),
        "drawerSettingsTitle":
            MessageLookupByLibrary.simpleMessage("Paramètres"),
        "drawerTasks": MessageLookupByLibrary.simpleMessage("Tâches"),
        "english": MessageLookupByLibrary.simpleMessage("English"),
        "firstName": MessageLookupByLibrary.simpleMessage(""),
        "homeScreenTitle": MessageLookupByLibrary.simpleMessage("Tâches"),
        "language_select":
            MessageLookupByLibrary.simpleMessage("Select Language"),
        "locale": MessageLookupByLibrary.simpleMessage("fr"),
        "loginScreenTitle": MessageLookupByLibrary.simpleMessage("Connexion"),
        "pageSettingsTitle": MessageLookupByLibrary.simpleMessage(""),
        "save": MessageLookupByLibrary.simpleMessage(""),
        "settingsScreenTitle":
            MessageLookupByLibrary.simpleMessage("Paramètres"),
        "taskName": MessageLookupByLibrary.simpleMessage(""),
        "taskPrice": MessageLookupByLibrary.simpleMessage(""),
        "taskSaveScreenTitle":
            MessageLookupByLibrary.simpleMessage("Enregistrer une tâche"),
        "tasksScreenTitle": MessageLookupByLibrary.simpleMessage("Tâches"),
        "title": MessageLookupByLibrary.simpleMessage(
            "Application de gestion des tâches"),
        "translate_menu_title": m0,
        "turkish": MessageLookupByLibrary.simpleMessage("Turkish")
      };
}
