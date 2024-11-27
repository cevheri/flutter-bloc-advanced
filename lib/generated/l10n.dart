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
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
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
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `List User`
  String get list_user {
    return Intl.message(
      'List User',
      name: 'list_user',
      desc: '',
      args: [],
    );
  }

  /// `Screen size is too small.`
  String get screen_size_error {
    return Intl.message(
      'Screen size is too small.',
      name: 'screen_size_error',
      desc: '',
      args: [],
    );
  }

  /// `Admin`
  String get admin {
    return Intl.message(
      'Admin',
      name: 'admin',
      desc: '',
      args: [],
    );
  }

  /// `Guest`
  String get guest {
    return Intl.message(
      'Guest',
      name: 'guest',
      desc: '',
      args: [],
    );
  }

  /// `Role`
  String get role {
    return Intl.message(
      'Role',
      name: 'role',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `First Name`
  String get first_name {
    return Intl.message(
      'First Name',
      name: 'first_name',
      desc: '',
      args: [],
    );
  }

  /// `Last Name`
  String get last_name {
    return Intl.message(
      'Last Name',
      name: 'last_name',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phone_number {
    return Intl.message(
      'Phone Number',
      name: 'phone_number',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get active {
    return Intl.message(
      'Active',
      name: 'active',
      desc: '',
      args: [],
    );
  }

  /// `Authorities`
  String get authorities {
    return Intl.message(
      'Authorities',
      name: 'authorities',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `Success`
  String get success {
    return Intl.message(
      'Success',
      name: 'success',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get failed {
    return Intl.message(
      'Failed',
      name: 'failed',
      desc: '',
      args: [],
    );
  }

  /// `Required Field`
  String get required_field {
    return Intl.message(
      'Required Field',
      name: 'required_field',
      desc: '',
      args: [],
    );
  }

  /// `Range is required`
  String get required_range {
    return Intl.message(
      'Range is required',
      name: 'required_range',
      desc: '',
      args: [],
    );
  }

  /// `List`
  String get list {
    return Intl.message(
      'List',
      name: 'list',
      desc: '',
      args: [],
    );
  }

  /// `Edit User`
  String get edit_user {
    return Intl.message(
      'Edit User',
      name: 'edit_user',
      desc: '',
      args: [],
    );
  }

  /// `Email is required`
  String get email_required {
    return Intl.message(
      'Email is required',
      name: 'email_required',
      desc: '',
      args: [],
    );
  }

  /// `Email must be a valid email address`
  String get email_pattern {
    return Intl.message(
      'Email must be a valid email address',
      name: 'email_pattern',
      desc: '',
      args: [],
    );
  }

  /// `Lastname is required`
  String get lastname_required {
    return Intl.message(
      'Lastname is required',
      name: 'lastname_required',
      desc: '',
      args: [],
    );
  }

  /// `Lastname must be at least 5 characters long`
  String get lastname_min_length {
    return Intl.message(
      'Lastname must be at least 5 characters long',
      name: 'lastname_min_length',
      desc: '',
      args: [],
    );
  }

  /// `Lastname cannot be more than 20 characters long`
  String get lastname_max_length {
    return Intl.message(
      'Lastname cannot be more than 20 characters long',
      name: 'lastname_max_length',
      desc: '',
      args: [],
    );
  }

  /// `Firstname is required`
  String get firstname_required {
    return Intl.message(
      'Firstname is required',
      name: 'firstname_required',
      desc: '',
      args: [],
    );
  }

  /// `Firstname must be at least 5 characters long`
  String get firstname_min_length {
    return Intl.message(
      'Firstname must be at least 5 characters long',
      name: 'firstname_min_length',
      desc: '',
      args: [],
    );
  }

  /// `Firstname cannot be more than 20 characters long`
  String get firstname_max_length {
    return Intl.message(
      'Firstname cannot be more than 20 characters long',
      name: 'firstname_max_length',
      desc: '',
      args: [],
    );
  }

  /// `Username is required`
  String get username_required {
    return Intl.message(
      'Username is required',
      name: 'username_required',
      desc: '',
      args: [],
    );
  }

  /// `Username cannot be more than 20 characters long`
  String get username_max_length {
    return Intl.message(
      'Username cannot be more than 20 characters long',
      name: 'username_max_length',
      desc: '',
      args: [],
    );
  }

  /// `Username must be at least 5 characters long`
  String get username_min_length {
    return Intl.message(
      'Username must be at least 5 characters long',
      name: 'username_min_length',
      desc: '',
      args: [],
    );
  }

  /// `Username must be a valid email address`
  String get username_regex_pattern {
    return Intl.message(
      'Username must be a valid email address',
      name: 'username_regex_pattern',
      desc: '',
      args: [],
    );
  }

  /// `Turkish`
  String get turkish {
    return Intl.message(
      'Turkish',
      name: 'turkish',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get english {
    return Intl.message(
      'English',
      name: 'english',
      desc: '',
      args: [],
    );
  }

  /// `Create User`
  String get create_user {
    return Intl.message(
      'Create User',
      name: 'create_user',
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

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get account {
    return Intl.message(
      'Account',
      name: 'account',
      desc: '',
      args: [],
    );
  }

  /// `Change Password`
  String get change_password {
    return Intl.message(
      'Change Password',
      name: 'change_password',
      desc: '',
      args: [],
    );
  }

  /// `Select Language`
  String get language_select {
    return Intl.message(
      'Select Language',
      name: 'language_select',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message(
      'Logout',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to logout?`
  String get logout_sure {
    return Intl.message(
      'Are you sure you want to logout?',
      name: 'logout_sure',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message(
      'Yes',
      name: 'yes',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get login_user_name {
    return Intl.message(
      'Username',
      name: 'login_user_name',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get login_password {
    return Intl.message(
      'Password',
      name: 'login_password',
      desc: '',
      args: [],
    );
  }

  /// `Current Password`
  String get current_password {
    return Intl.message(
      'Current Password',
      name: 'current_password',
      desc: '',
      args: [],
    );
  }

  /// `New Password`
  String get new_password {
    return Intl.message(
      'New Password',
      name: 'new_password',
      desc: '',
      args: [],
    );
  }

  /// `Forgot Password`
  String get password_forgot {
    return Intl.message(
      'Forgot Password',
      name: 'password_forgot',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message(
      'Register',
      name: 'register',
      desc: '',
      args: [],
    );
  }

  /// `Password cannot be more than 6 characters long`
  String get password_max_length {
    return Intl.message(
      'Password cannot be more than 6 characters long',
      name: 'password_max_length',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 5 characters long`
  String get password_min_length {
    return Intl.message(
      'Password must be at least 5 characters long',
      name: 'password_min_length',
      desc: '',
      args: [],
    );
  }

  /// `Password is required`
  String get password_required {
    return Intl.message(
      'Password is required',
      name: 'password_required',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login_button {
    return Intl.message(
      'Login',
      name: 'login_button',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Send Email`
  String get email_send {
    return Intl.message(
      'Send Email',
      name: 'email_send',
      desc: '',
      args: [],
    );
  }

  /// `{translate, select, account{Account} userManagement{User Management} settings{Settings}  logout{Logout}  info{Info} language{Language}  theme{Theme}  create{Create}  list{List/Edit} other{Other}}`
  String translate_menu_title(Object translate) {
    return Intl.select(
      translate,
      {
        'account': 'Account',
        'userManagement': 'User Management',
        'settings': 'Settings',
        'logout': 'Logout',
        'info': 'Info',
        'language': 'Language',
        'theme': 'Theme',
        'create': 'Create',
        'list': 'List/Edit',
        'other': 'Other',
      },
      name: 'translate_menu_title',
      desc: '',
      args: [translate],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
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
