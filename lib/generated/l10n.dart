// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null, 'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate =
    AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name); 
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;
 
      return instance;
    });
  } 

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null, 'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `en`
  String get locale {
    return Intl.message(
      'en',
      name: 'locale',
      desc: '',
      args: [],
    );
  }

  /// `Task Management App`
  String get title {
    return Intl.message(
      'Task Management App',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get homeScreenTitle {
    return Intl.message(
      'Home',
      name: 'homeScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get loginScreenTitle {
    return Intl.message(
      'Login',
      name: 'loginScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settingsScreenTitle {
    return Intl.message(
      'Settings',
      name: 'settingsScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get accountScreenTitle {
    return Intl.message(
      'Account',
      name: 'accountScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tasks`
  String get tasksScreenTitle {
    return Intl.message(
      'Tasks',
      name: 'tasksScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Save or Update Task`
  String get taskSaveScreenTitle {
    return Intl.message(
      'Save or Update Task',
      name: 'taskSaveScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get drawerMenuHome {
    return Intl.message(
      'Home',
      name: 'drawerMenuHome',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get drawerSettingsTitle {
    return Intl.message(
      'Settings',
      name: 'drawerSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get drawerLogoutTitle {
    return Intl.message(
      'Logout',
      name: 'drawerLogoutTitle',
      desc: '',
      args: [],
    );
  }

  /// `Tasks`
  String get drawerTasks {
    return Intl.message(
      'Tasks',
      name: 'drawerTasks',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get pageSettingsTitle {
    return Intl.message(
      'Settings',
      name: 'pageSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `First Name`
  String get firstName {
    return Intl.message(
      'First Name',
      name: 'firstName',
      desc: '',
      args: [],
    );
  }

  /// `Task Price`
  String get taskPrice {
    return Intl.message(
      'Task Price',
      name: 'taskPrice',
      desc: '',
      args: [],
    );
  }

  /// `Task Name`
  String get taskName {
    return Intl.message(
      'Task Name',
      name: 'taskName',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'fr'),
      Locale.fromSubtags(languageCode: 'tr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}