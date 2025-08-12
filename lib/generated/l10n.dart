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
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

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
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Screen size is too small.`
  String get screen_size_error {
    return Intl.message('Screen size is too small.', name: 'screen_size_error', desc: '', args: []);
  }

  /// `Admin`
  String get admin {
    return Intl.message('Admin', name: 'admin', desc: '', args: []);
  }

  /// `Guest`
  String get guest {
    return Intl.message('Guest', name: 'guest', desc: '', args: []);
  }

  /// `Role`
  String get role {
    return Intl.message('Role', name: 'role', desc: '', args: []);
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `First Name`
  String get first_name {
    return Intl.message('First Name', name: 'first_name', desc: '', args: []);
  }

  /// `Last Name`
  String get last_name {
    return Intl.message('Last Name', name: 'last_name', desc: '', args: []);
  }

  /// `Phone Number`
  String get phone_number {
    return Intl.message('Phone Number', name: 'phone_number', desc: '', args: []);
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Active`
  String get active {
    return Intl.message('Active', name: 'active', desc: '', args: []);
  }

  /// `Authorities`
  String get authorities {
    return Intl.message('Authorities', name: 'authorities', desc: '', args: []);
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `Success`
  String get success {
    return Intl.message('Success', name: 'success', desc: '', args: []);
  }

  /// `Failed`
  String get failed {
    return Intl.message('Failed', name: 'failed', desc: '', args: []);
  }

  /// `Required Field`
  String get required_field {
    return Intl.message('Required Field', name: 'required_field', desc: '', args: []);
  }

  /// `Field must be at least 2 characters long`
  String get min_length_2 {
    return Intl.message('Field must be at least 2 characters long', name: 'min_length_2', desc: '', args: []);
  }

  /// `Field must be at least 3 characters long`
  String get min_length_3 {
    return Intl.message('Field must be at least 3 characters long', name: 'min_length_3', desc: '', args: []);
  }

  /// `Field must be at least 4 characters long`
  String get min_length_4 {
    return Intl.message('Field must be at least 4 characters long', name: 'min_length_4', desc: '', args: []);
  }

  /// `Field must be at least 5 characters long`
  String get min_length_5 {
    return Intl.message('Field must be at least 5 characters long', name: 'min_length_5', desc: '', args: []);
  }

  /// `Field cannot be more than 10 characters long`
  String get max_length_10 {
    return Intl.message('Field cannot be more than 10 characters long', name: 'max_length_10', desc: '', args: []);
  }

  /// `Field cannot be more than 20 characters long`
  String get max_length_20 {
    return Intl.message('Field cannot be more than 20 characters long', name: 'max_length_20', desc: '', args: []);
  }

  /// `Field cannot be more than 50 characters long`
  String get max_length_50 {
    return Intl.message('Field cannot be more than 50 characters long', name: 'max_length_50', desc: '', args: []);
  }

  /// `Field cannot be more than 100 characters long`
  String get max_length_100 {
    return Intl.message('Field cannot be more than 100 characters long', name: 'max_length_100', desc: '', args: []);
  }

  /// `Field cannot be more than 250 characters long`
  String get max_length_250 {
    return Intl.message('Field cannot be more than 250 characters long', name: 'max_length_250', desc: '', args: []);
  }

  /// `Field cannot be more than 500 characters long`
  String get max_length_500 {
    return Intl.message('Field cannot be more than 500 characters long', name: 'max_length_500', desc: '', args: []);
  }

  /// `Field cannot be more than 1000 characters long`
  String get max_length_1000 {
    return Intl.message('Field cannot be more than 1000 characters long', name: 'max_length_1000', desc: '', args: []);
  }

  /// `Field cannot be more than 4000 characters long`
  String get max_length_4000 {
    return Intl.message('Field cannot be more than 4000 characters long', name: 'max_length_4000', desc: '', args: []);
  }

  /// `Range is required`
  String get required_range {
    return Intl.message('Range is required', name: 'required_range', desc: '', args: []);
  }

  /// `List`
  String get list {
    return Intl.message('List', name: 'list', desc: '', args: []);
  }

  /// `Filter`
  String get filter {
    return Intl.message('Filter', name: 'filter', desc: '', args: []);
  }

  /// `List User`
  String get list_user {
    return Intl.message('List User', name: 'list_user', desc: '', args: []);
  }

  /// `New User`
  String get new_user {
    return Intl.message('New User', name: 'new_user', desc: '', args: []);
  }

  /// `Edit User`
  String get edit_user {
    return Intl.message('Edit User', name: 'edit_user', desc: '', args: []);
  }

  /// `View User`
  String get view_user {
    return Intl.message('View User', name: 'view_user', desc: '', args: []);
  }

  /// `Delete User`
  String get delete_user {
    return Intl.message('Delete User', name: 'delete_user', desc: '', args: []);
  }

  /// `Email must be a valid email address`
  String get email_pattern {
    return Intl.message('Email must be a valid email address', name: 'email_pattern', desc: '', args: []);
  }

  /// `Turkish`
  String get turkish {
    return Intl.message('Turkish', name: 'turkish', desc: '', args: []);
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `Create User`
  String get create_user {
    return Intl.message('Create User', name: 'create_user', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Back`
  String get back {
    return Intl.message('Back', name: 'back', desc: '', args: []);
  }

  /// `Are you sure you want to delete?`
  String get delete_confirmation {
    return Intl.message('Are you sure you want to delete?', name: 'delete_confirmation', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Change Password`
  String get change_password {
    return Intl.message('Change Password', name: 'change_password', desc: '', args: []);
  }

  /// `Select Language`
  String get language_select {
    return Intl.message('Select Language', name: 'language_select', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Are you sure you want to logout?`
  String get logout_sure {
    return Intl.message('Are you sure you want to logout?', name: 'logout_sure', desc: '', args: []);
  }

  /// `Yes`
  String get yes {
    return Intl.message('Yes', name: 'yes', desc: '', args: []);
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `Warning`
  String get warning {
    return Intl.message('Warning', name: 'warning', desc: '', args: []);
  }

  /// `You have unsaved changes. Are you sure you want to leave?`
  String get unsaved_changes {
    return Intl.message(
      'You have unsaved changes. Are you sure you want to leave?',
      name: 'unsaved_changes',
      desc: '',
      args: [],
    );
  }

  /// `No changes made`
  String get no_changes_made {
    return Intl.message('No changes made', name: 'no_changes_made', desc: '', args: []);
  }

  /// `No Data`
  String get no_data {
    return Intl.message('No Data', name: 'no_data', desc: '', args: []);
  }

  /// `Username`
  String get login_user_name {
    return Intl.message('Username', name: 'login_user_name', desc: '', args: []);
  }

  /// `Password`
  String get login_password {
    return Intl.message('Password', name: 'login_password', desc: '', args: []);
  }

  /// `Current Password`
  String get current_password {
    return Intl.message('Current Password', name: 'current_password', desc: '', args: []);
  }

  /// `New Password`
  String get new_password {
    return Intl.message('New Password', name: 'new_password', desc: '', args: []);
  }

  /// `Forgot Password`
  String get password_forgot {
    return Intl.message('Forgot Password', name: 'password_forgot', desc: '', args: []);
  }

  /// `Register`
  String get register {
    return Intl.message('Register', name: 'register', desc: '', args: []);
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
    return Intl.message('Password must be at least 5 characters long', name: 'password_min_length', desc: '', args: []);
  }

  /// `Login`
  String get login_button {
    return Intl.message('Login', name: 'login_button', desc: '', args: []);
  }

  /// `Loading...`
  String get loading {
    return Intl.message('Loading...', name: 'loading', desc: '', args: []);
  }

  /// `Send Email`
  String get email_send {
    return Intl.message('Send Email', name: 'email_send', desc: '', args: []);
  }

  /// `{translate, select, account{Account} userManagement{User Management} settings{Settings}  logout{Logout}  info{Info} language{Language}  theme{Theme}  new_user{New}  list_user{List} other{Other}}`
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
        'new_user': 'New',
        'list_user': 'List',
        'other': 'Other',
      },
      name: 'translate_menu_title',
      desc: '',
      args: [translate],
    );
  }

  /// `Login with Email`
  String get login_with_email {
    return Intl.message('Login with Email', name: 'login_with_email', desc: '', args: []);
  }

  /// `Send OTP Code`
  String get send_otp_code {
    return Intl.message('Send OTP Code', name: 'send_otp_code', desc: '', args: []);
  }

  /// `Invalid email address`
  String get invalid_email {
    return Intl.message('Invalid email address', name: 'invalid_email', desc: '', args: []);
  }

  /// `Resend OTP Code`
  String get resend_otp_code {
    return Intl.message('Resend OTP Code', name: 'resend_otp_code', desc: '', args: []);
  }

  /// `Verify OTP Code`
  String get verify_otp_code {
    return Intl.message('Verify OTP Code', name: 'verify_otp_code', desc: '', args: []);
  }

  /// `Only numbers are allowed`
  String get only_numbers {
    return Intl.message('Only numbers are allowed', name: 'only_numbers', desc: '', args: []);
  }

  /// `OTP must be 6 characters long`
  String get otp_length {
    return Intl.message('OTP must be 6 characters long', name: 'otp_length', desc: '', args: []);
  }

  /// `OTP Code`
  String get otp_code {
    return Intl.message('OTP Code', name: 'otp_code', desc: '', args: []);
  }

  /// `OTP sent to`
  String get otp_sent_to {
    return Intl.message('OTP sent to', name: 'otp_sent_to', desc: '', args: []);
  }

  /// `Task Save`
  String get taskSaveScreenTitle {
    return Intl.message('Task Save', name: 'taskSaveScreenTitle', desc: '', args: []);
  }

  /// `Task Name`
  String get taskName {
    return Intl.message('Task Name', name: 'taskName', desc: '', args: []);
  }

  /// `Task Price`
  String get taskPrice {
    return Intl.message('Task Price', name: 'taskPrice', desc: '', args: []);
  }

  /// `Theme`
  String get theme {
    return Intl.message('Theme', name: 'theme', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message('Dashboard', name: 'dashboard', desc: '', args: []);
  }

  /// `Refresh`
  String get refresh {
    return Intl.message('Refresh', name: 'refresh', desc: '', args: []);
  }

  /// `Leads`
  String get leads {
    return Intl.message('Leads', name: 'leads', desc: '', args: []);
  }

  /// `Customers`
  String get customers {
    return Intl.message('Customers', name: 'customers', desc: '', args: []);
  }

  /// `Revenue`
  String get revenue {
    return Intl.message('Revenue', name: 'revenue', desc: '', args: []);
  }

  /// `Chart / KPI Placeholder`
  String get chart_kpi_placeholder {
    return Intl.message('Chart / KPI Placeholder', name: 'chart_kpi_placeholder', desc: '', args: []);
  }

  /// `Recent Activity`
  String get recent_activity {
    return Intl.message('Recent Activity', name: 'recent_activity', desc: '', args: []);
  }

  /// `Sample activity item`
  String get sample_activity_item {
    return Intl.message('Sample activity item', name: 'sample_activity_item', desc: '', args: []);
  }

  /// `Subtitle / Context`
  String get subtitle_context {
    return Intl.message('Subtitle / Context', name: 'subtitle_context', desc: '', args: []);
  }

  /// `just now`
  String get just_now {
    return Intl.message('just now', name: 'just_now', desc: '', args: []);
  }

  /// `Quick Actions`
  String get quick_actions {
    return Intl.message('Quick Actions', name: 'quick_actions', desc: '', args: []);
  }

  /// `New Lead`
  String get new_lead {
    return Intl.message('New Lead', name: 'new_lead', desc: '', args: []);
  }

  /// `Add Task`
  String get add_task {
    return Intl.message('Add Task', name: 'add_task', desc: '', args: []);
  }

  /// `New Deal`
  String get new_deal {
    return Intl.message('New Deal', name: 'new_deal', desc: '', args: []);
  }

  /// `Send Email`
  String get send_email_action {
    return Intl.message('Send Email', name: 'send_email_action', desc: '', args: []);
  }

  /// `More`
  String get more {
    return Intl.message('More', name: 'more', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en'), Locale.fromSubtags(languageCode: 'tr')];
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
