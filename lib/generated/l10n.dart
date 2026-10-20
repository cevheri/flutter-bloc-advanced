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

  /// `Field must be at least 4 characters long`
  String get min_length_4 {
    return Intl.message('Field must be at least 4 characters long', name: 'min_length_4', desc: '', args: []);
  }

  /// `Field cannot be more than 20 characters long`
  String get max_length_20 {
    return Intl.message('Field cannot be more than 20 characters long', name: 'max_length_20', desc: '', args: []);
  }

  /// `Field cannot be more than 100 characters long`
  String get max_length_100 {
    return Intl.message('Field cannot be more than 100 characters long', name: 'max_length_100', desc: '', args: []);
  }

  /// `Range is required`
  String get required_range {
    return Intl.message('Range is required', name: 'required_range', desc: '', args: []);
  }

  /// `List`
  String get list {
    return Intl.message('List', name: 'list', desc: '', args: []);
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

  /// `Ensure your account is using a long, random password to stay secure.`
  String get change_password_description {
    return Intl.message(
      'Ensure your account is using a long, random password to stay secure.',
      name: 'change_password_description',
      desc: '',
      args: [],
    );
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

  /// `Password cannot be more than {max} characters long`
  String password_max_length(int max) {
    return Intl.message(
      'Password cannot be more than $max characters long',
      name: 'password_max_length',
      desc: '',
      args: [max],
    );
  }

  /// `Password must be at least {min} characters long`
  String password_min_length(int min) {
    return Intl.message(
      'Password must be at least $min characters long',
      name: 'password_min_length',
      desc: '',
      args: [min],
    );
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
  String translate_menu_title(String translate) {
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

  /// `Quick Actions`
  String get quick_actions {
    return Intl.message('Quick Actions', name: 'quick_actions', desc: '', args: []);
  }

  /// `Join the Community`
  String get community_title {
    return Intl.message('Join the Community', name: 'community_title', desc: '', args: []);
  }

  /// `This project is open source. Your contributions make it better!`
  String get community_subtitle {
    return Intl.message(
      'This project is open source. Your contributions make it better!',
      name: 'community_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Star & Fork`
  String get community_star {
    return Intl.message('Star & Fork', name: 'community_star', desc: '', args: []);
  }

  /// `Open an Issue`
  String get community_issue {
    return Intl.message('Open an Issue', name: 'community_issue', desc: '', args: []);
  }

  /// `Discussions`
  String get community_discussions {
    return Intl.message('Discussions', name: 'community_discussions', desc: '', args: []);
  }

  /// `Contribute`
  String get community_contribute {
    return Intl.message('Contribute', name: 'community_contribute', desc: '', args: []);
  }

  /// `Translate`
  String get community_translate {
    return Intl.message('Translate', name: 'community_translate', desc: '', args: []);
  }

  /// `Sponsor`
  String get community_sponsor {
    return Intl.message('Sponsor', name: 'community_sponsor', desc: '', args: []);
  }

  /// `Documentation`
  String get community_docs {
    return Intl.message('Documentation', name: 'community_docs', desc: '', args: []);
  }

  /// `Help & Resources`
  String get help_resources {
    return Intl.message('Help & Resources', name: 'help_resources', desc: '', args: []);
  }

  /// `Visit our website for documentation and guides`
  String get help_resources_subtitle {
    return Intl.message(
      'Visit our website for documentation and guides',
      name: 'help_resources_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Website`
  String get website {
    return Intl.message('Website', name: 'website', desc: '', args: []);
  }

  /// `Invalid access token`
  String get error_auth_invalid_access_token {
    return Intl.message('Invalid access token', name: 'error_auth_invalid_access_token', desc: '', args: []);
  }

  /// `Login failed`
  String get error_auth_login_failed {
    return Intl.message('Login failed', name: 'error_auth_login_failed', desc: '', args: []);
  }

  /// `Could not send the OTP code`
  String get error_auth_send_otp_failed {
    return Intl.message('Could not send the OTP code', name: 'error_auth_send_otp_failed', desc: '', args: []);
  }

  /// `OTP validation failed`
  String get error_auth_otp_validation {
    return Intl.message('OTP validation failed', name: 'error_auth_otp_validation', desc: '', args: []);
  }

  /// `Could not save the session`
  String get error_auth_session_persist_failed {
    return Intl.message('Could not save the session', name: 'error_auth_session_persist_failed', desc: '', args: []);
  }

  /// `Admin user cannot be deleted`
  String get error_user_cannot_delete_admin {
    return Intl.message('Admin user cannot be deleted', name: 'error_user_cannot_delete_admin', desc: '', args: []);
  }

  /// `No authorities found`
  String get error_user_no_authorities {
    return Intl.message('No authorities found', name: 'error_user_no_authorities', desc: '', args: []);
  }

  /// `Both current and new password are required`
  String get error_account_password_required {
    return Intl.message(
      'Both current and new password are required',
      name: 'error_account_password_required',
      desc: '',
      args: [],
    );
  }

  /// `New password must be different from current password`
  String get error_account_passwords_same {
    return Intl.message(
      'New password must be different from current password',
      name: 'error_account_passwords_same',
      desc: '',
      args: [],
    );
  }

  /// `Could not change the language`
  String get error_settings_change_language_failed {
    return Intl.message(
      'Could not change the language',
      name: 'error_settings_change_language_failed',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong`
  String get error_generic {
    return Intl.message('Something went wrong', name: 'error_generic', desc: '', args: []);
  }

  /// `Extended Information`
  String get user_extended_info_title {
    return Intl.message('Extended Information', name: 'user_extended_info_title', desc: '', args: []);
  }

  /// `Extended Info`
  String get user_extended_info_button {
    return Intl.message('Extended Info', name: 'user_extended_info_button', desc: '', args: []);
  }

  /// `Saved`
  String get user_extended_info_saved {
    return Intl.message('Saved', name: 'user_extended_info_saved', desc: '', args: []);
  }

  /// `Save failed: {error}`
  String user_extended_info_save_failed(String error) {
    return Intl.message('Save failed: $error', name: 'user_extended_info_save_failed', desc: '', args: [error]);
  }

  /// `Access denied`
  String get forbidden_title {
    return Intl.message('Access denied', name: 'forbidden_title', desc: '', args: []);
  }

  /// `You do not have permission to view this page.`
  String get forbidden_message {
    return Intl.message('You do not have permission to view this page.', name: 'forbidden_message', desc: '', args: []);
  }

  /// `Back to home`
  String get forbidden_back_home {
    return Intl.message('Back to home', name: 'forbidden_back_home', desc: '', args: []);
  }

  /// `The connection could not be verified as secure, so it was blocked. Try again later or on another network.`
  String get error_network_cert_invalid {
    return Intl.message(
      'The connection could not be verified as secure, so it was blocked. Try again later or on another network.',
      name: 'error_network_cert_invalid',
      desc: '',
      args: [],
    );
  }

  /// `You were signed out due to inactivity.`
  String get idle_timeout_signed_out {
    return Intl.message('You were signed out due to inactivity.', name: 'idle_timeout_signed_out', desc: '', args: []);
  }

  /// `Could not open {url}`
  String error_link_open_failed(String url) {
    return Intl.message('Could not open $url', name: 'error_link_open_failed', desc: '', args: [url]);
  }

  /// `Update Required`
  String get force_update_title {
    return Intl.message('Update Required', name: 'force_update_title', desc: '', args: []);
  }

  /// `A new version is available. Please update to continue using the app.`
  String get force_update_message {
    return Intl.message(
      'A new version is available. Please update to continue using the app.',
      name: 'force_update_message',
      desc: '',
      args: [],
    );
  }

  /// `Current: {currentVersion}  •  Required: {minimumVersion}`
  String force_update_versions(String currentVersion, String minimumVersion) {
    return Intl.message(
      'Current: $currentVersion  •  Required: $minimumVersion',
      name: 'force_update_versions',
      desc: '',
      args: [currentVersion, minimumVersion],
    );
  }

  /// `Update Now`
  String get force_update_button {
    return Intl.message('Update Now', name: 'force_update_button', desc: '', args: []);
  }

  /// `Open your app store to install the latest version.`
  String get force_update_no_store_link {
    return Intl.message(
      'Open your app store to install the latest version.',
      name: 'force_update_no_store_link',
      desc: '',
      args: [],
    );
  }

  /// `The update link is not valid. Open your app store to install the latest version.`
  String get force_update_store_link_invalid {
    return Intl.message(
      'The update link is not valid. Open your app store to install the latest version.',
      name: 'force_update_store_link_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Under Maintenance`
  String get maintenance_title {
    return Intl.message('Under Maintenance', name: 'maintenance_title', desc: '', args: []);
  }

  /// `We are performing scheduled maintenance. Please check back soon.`
  String get maintenance_message {
    return Intl.message(
      'We are performing scheduled maintenance. Please check back soon.',
      name: 'maintenance_message',
      desc: '',
      args: [],
    );
  }

  /// `Estimated end: {time}`
  String maintenance_estimated_end(String time) {
    return Intl.message('Estimated end: $time', name: 'maintenance_estimated_end', desc: '', args: [time]);
  }

  /// `Try Again`
  String get maintenance_retry {
    return Intl.message('Try Again', name: 'maintenance_retry', desc: '', args: []);
  }

  /// `Could not load the users`
  String get user_list_load_failed {
    return Intl.message('Could not load the users', name: 'user_list_load_failed', desc: '', args: []);
  }

  /// `Could not delete the user`
  String get user_delete_failed {
    return Intl.message('Could not delete the user', name: 'user_delete_failed', desc: '', args: []);
  }

  /// `Could not load the user`
  String get user_load_failed {
    return Intl.message('Could not load the user', name: 'user_load_failed', desc: '', args: []);
  }

  /// `Roles unavailable`
  String get authorities_load_failed {
    return Intl.message('Roles unavailable', name: 'authorities_load_failed', desc: '', args: []);
  }

  /// `You were signed out, but some stored data could not be removed from this device.`
  String get logout_stored_data_left {
    return Intl.message(
      'You were signed out, but some stored data could not be removed from this device.',
      name: 'logout_stored_data_left',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Users`
  String get users {
    return Intl.message('Users', name: 'users', desc: '', args: []);
  }

  /// `New`
  String get new_item {
    return Intl.message('New', name: 'new_item', desc: '', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `No internet connection`
  String get connectivity_offline {
    return Intl.message('No internet connection', name: 'connectivity_offline', desc: '', args: []);
  }

  /// `Page Not Found`
  String get not_found_title {
    return Intl.message('Page Not Found', name: 'not_found_title', desc: '', args: []);
  }

  /// `The page you requested could not be found.`
  String get not_found_message {
    return Intl.message('The page you requested could not be found.', name: 'not_found_message', desc: '', args: []);
  }

  /// `Dynamic Forms`
  String get dynamic_forms {
    return Intl.message('Dynamic Forms', name: 'dynamic_forms', desc: '', args: []);
  }

  /// `Dark`
  String get theme_mode_dark {
    return Intl.message('Dark', name: 'theme_mode_dark', desc: '', args: []);
  }

  /// `Light`
  String get theme_mode_light {
    return Intl.message('Light', name: 'theme_mode_light', desc: '', args: []);
  }

  /// `Expand`
  String get sidebar_expand {
    return Intl.message('Expand', name: 'sidebar_expand', desc: '', args: []);
  }

  /// `Collapse`
  String get sidebar_collapse {
    return Intl.message('Collapse', name: 'sidebar_collapse', desc: '', args: []);
  }

  /// `Type a command or search...`
  String get command_palette_hint {
    return Intl.message('Type a command or search...', name: 'command_palette_hint', desc: '', args: []);
  }

  /// `No results found`
  String get command_palette_no_results {
    return Intl.message('No results found', name: 'command_palette_no_results', desc: '', args: []);
  }

  /// `Go to home`
  String get command_palette_home_description {
    return Intl.message('Go to home', name: 'command_palette_home_description', desc: '', args: []);
  }

  /// `Manage users`
  String get command_palette_users_description {
    return Intl.message('Manage users', name: 'command_palette_users_description', desc: '', args: []);
  }

  /// `Create a new user`
  String get command_palette_new_user_description {
    return Intl.message('Create a new user', name: 'command_palette_new_user_description', desc: '', args: []);
  }

  /// `Your profile`
  String get command_palette_account_description {
    return Intl.message('Your profile', name: 'command_palette_account_description', desc: '', args: []);
  }

  /// `App preferences`
  String get command_palette_settings_description {
    return Intl.message('App preferences', name: 'command_palette_settings_description', desc: '', args: []);
  }

  /// `Update password`
  String get command_palette_change_password_description {
    return Intl.message('Update password', name: 'command_palette_change_password_description', desc: '', args: []);
  }

  /// `Scale from prototype\nto production.`
  String get login_brand_headline {
    return Intl.message('Scale from prototype\nto production.', name: 'login_brand_headline', desc: '', args: []);
  }

  /// `Authentication, role-based access, user management,\ntheming, and multi-environment support in one robust starter.`
  String get login_brand_description {
    return Intl.message(
      'Authentication, role-based access, user management,\ntheming, and multi-environment support in one robust starter.',
      name: 'login_brand_description',
      desc: '',
      args: [],
    );
  }

  /// `Platforms`
  String get login_brand_stat_platforms {
    return Intl.message('Platforms', name: 'login_brand_stat_platforms', desc: '', args: []);
  }

  /// `Core Layers`
  String get login_brand_stat_layers {
    return Intl.message('Core Layers', name: 'login_brand_stat_layers', desc: '', args: []);
  }

  /// `BLoC Ready`
  String get login_brand_stat_bloc_ready {
    return Intl.message('BLoC Ready', name: 'login_brand_stat_bloc_ready', desc: '', args: []);
  }

  /// `Authentication & Access Control`
  String get login_feature_auth_title {
    return Intl.message('Authentication & Access Control', name: 'login_feature_auth_title', desc: '', args: []);
  }

  /// `Password and OTP login flows with role-based routing guards.`
  String get login_feature_auth_description {
    return Intl.message(
      'Password and OTP login flows with role-based routing guards.',
      name: 'login_feature_auth_description',
      desc: '',
      args: [],
    );
  }

  /// `Clean Architecture`
  String get login_feature_architecture_title {
    return Intl.message('Clean Architecture', name: 'login_feature_architecture_title', desc: '', args: []);
  }

  /// `BLoC + Repository pattern with clear separation of concerns.`
  String get login_feature_architecture_description {
    return Intl.message(
      'BLoC + Repository pattern with clear separation of concerns.',
      name: 'login_feature_architecture_description',
      desc: '',
      args: [],
    );
  }

  /// `Mock to Real API`
  String get login_feature_mock_api_title {
    return Intl.message('Mock to Real API', name: 'login_feature_mock_api_title', desc: '', args: []);
  }

  /// `Develop locally with mock data and switch to production endpoints.`
  String get login_feature_mock_api_description {
    return Intl.message(
      'Develop locally with mock data and switch to production endpoints.',
      name: 'login_feature_mock_api_description',
      desc: '',
      args: [],
    );
  }

  /// `Welcome back`
  String get login_welcome_title {
    return Intl.message('Welcome back', name: 'login_welcome_title', desc: '', args: []);
  }

  /// `Enter your credentials to access your account`
  String get login_welcome_subtitle {
    return Intl.message(
      'Enter your credentials to access your account',
      name: 'login_welcome_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `or`
  String get login_or {
    return Intl.message('or', name: 'login_or', desc: '', args: []);
  }

  /// `Don't have an account? `
  String get login_no_account {
    return Intl.message('Don\'t have an account? ', name: 'login_no_account', desc: '', args: []);
  }

  /// `Switch to light mode`
  String get login_switch_to_light_mode {
    return Intl.message('Switch to light mode', name: 'login_switch_to_light_mode', desc: '', args: []);
  }

  /// `Switch to dark mode`
  String get login_switch_to_dark_mode {
    return Intl.message('Switch to dark mode', name: 'login_switch_to_dark_mode', desc: '', args: []);
  }

  /// `Enter your email to receive OTP code`
  String get login_otp_email_instructions {
    return Intl.message(
      'Enter your email to receive OTP code',
      name: 'login_otp_email_instructions',
      desc: '',
      args: [],
    );
  }

  /// `OTP sent to {email}`
  String otp_sent_to_email(String email) {
    return Intl.message('OTP sent to $email', name: 'otp_sent_to_email', desc: '', args: [email]);
  }

  /// `Open Source`
  String get community_open_source {
    return Intl.message('Open Source', name: 'community_open_source', desc: '', args: []);
  }

  /// `Create your account`
  String get register_subtitle {
    return Intl.message('Create your account', name: 'register_subtitle', desc: '', args: []);
  }

  /// `Enter your email address and we'll send you a link to reset your password.`
  String get forgot_password_description {
    return Intl.message(
      'Enter your email address and we\'ll send you a link to reset your password.',
      name: 'forgot_password_description',
      desc: '',
      args: [],
    );
  }

  /// `Manage your account preferences`
  String get settings_subtitle {
    return Intl.message('Manage your account preferences', name: 'settings_subtitle', desc: '', args: []);
  }

  /// `View or edit your profile information`
  String get settings_account_subtitle {
    return Intl.message('View or edit your profile information', name: 'settings_account_subtitle', desc: '', args: []);
  }

  /// `Update your password securely`
  String get settings_change_password_subtitle {
    return Intl.message('Update your password securely', name: 'settings_change_password_subtitle', desc: '', args: []);
  }

  /// `Appearance`
  String get settings_appearance {
    return Intl.message('Appearance', name: 'settings_appearance', desc: '', args: []);
  }

  /// `Choose your preferred theme style`
  String get settings_theme_subtitle {
    return Intl.message('Choose your preferred theme style', name: 'settings_theme_subtitle', desc: '', args: []);
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `Dashboard Error`
  String get dashboard_error_title {
    return Intl.message('Dashboard Error', name: 'dashboard_error_title', desc: '', args: []);
  }

  /// `System Dashboard`
  String get dashboard_title {
    return Intl.message('System Dashboard', name: 'dashboard_title', desc: '', args: []);
  }

  /// `Connectivity`
  String get dashboard_connectivity {
    return Intl.message('Connectivity', name: 'dashboard_connectivity', desc: '', args: []);
  }

  /// `Online`
  String get dashboard_online {
    return Intl.message('Online', name: 'dashboard_online', desc: '', args: []);
  }

  /// `Offline`
  String get dashboard_offline {
    return Intl.message('Offline', name: 'dashboard_offline', desc: '', args: []);
  }

  /// `Circuit Breaker`
  String get dashboard_circuit_breaker {
    return Intl.message('Circuit Breaker', name: 'dashboard_circuit_breaker', desc: '', args: []);
  }

  /// `{count, plural, =1{1 endpoint} other{{count} endpoints}}`
  String dashboard_endpoint_count(int count) {
    return Intl.plural(
      count,
      one: '1 endpoint',
      other: '$count endpoints',
      name: 'dashboard_endpoint_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count} open`
  String dashboard_open_count(int count) {
    return Intl.message('$count open', name: 'dashboard_open_count', desc: '', args: [count]);
  }

  /// `Cache`
  String get dashboard_cache {
    return Intl.message('Cache', name: 'dashboard_cache', desc: '', args: []);
  }

  /// `{count, plural, =1{1 item cached} other{{count} items cached}}`
  String dashboard_cached_item_count(int count) {
    return Intl.plural(
      count,
      one: '1 item cached',
      other: '$count items cached',
      name: 'dashboard_cached_item_count',
      desc: '',
      args: [count],
    );
  }

  /// `Feature Flags`
  String get dashboard_feature_flags {
    return Intl.message('Feature Flags', name: 'dashboard_feature_flags', desc: '', args: []);
  }

  /// `{enabled}/{total} enabled`
  String dashboard_feature_flags_enabled(int enabled, int total) {
    return Intl.message(
      '$enabled/$total enabled',
      name: 'dashboard_feature_flags_enabled',
      desc: '',
      args: [enabled, total],
    );
  }

  /// `Circuit Breaker Health`
  String get dashboard_circuit_breaker_health {
    return Intl.message('Circuit Breaker Health', name: 'dashboard_circuit_breaker_health', desc: '', args: []);
  }

  /// `No endpoints tracked yet`
  String get dashboard_no_endpoints {
    return Intl.message('No endpoints tracked yet', name: 'dashboard_no_endpoints', desc: '', args: []);
  }

  /// `Failures: {count}`
  String dashboard_failure_count(int count) {
    return Intl.message('Failures: $count', name: 'dashboard_failure_count', desc: '', args: [count]);
  }

  /// `No feature flags configured`
  String get dashboard_no_feature_flags {
    return Intl.message('No feature flags configured', name: 'dashboard_no_feature_flags', desc: '', args: []);
  }

  /// `App Configuration`
  String get dashboard_app_configuration {
    return Intl.message('App Configuration', name: 'dashboard_app_configuration', desc: '', args: []);
  }

  /// `Current Version`
  String get dashboard_current_version {
    return Intl.message('Current Version', name: 'dashboard_current_version', desc: '', args: []);
  }

  /// `Minimum Version`
  String get dashboard_minimum_version {
    return Intl.message('Minimum Version', name: 'dashboard_minimum_version', desc: '', args: []);
  }

  /// `Maintenance Mode`
  String get dashboard_maintenance_mode {
    return Intl.message('Maintenance Mode', name: 'dashboard_maintenance_mode', desc: '', args: []);
  }

  /// `ON`
  String get dashboard_on {
    return Intl.message('ON', name: 'dashboard_on', desc: '', args: []);
  }

  /// `OFF`
  String get dashboard_off {
    return Intl.message('OFF', name: 'dashboard_off', desc: '', args: []);
  }

  /// `Environment`
  String get dashboard_environment {
    return Intl.message('Environment', name: 'dashboard_environment', desc: '', args: []);
  }

  /// `Interceptor Chain`
  String get dashboard_interceptor_chain {
    return Intl.message('Interceptor Chain', name: 'dashboard_interceptor_chain', desc: '', args: []);
  }

  /// `Clear Cache`
  String get dashboard_clear_cache {
    return Intl.message('Clear Cache', name: 'dashboard_clear_cache', desc: '', args: []);
  }

  /// `Reset Circuit Breakers`
  String get dashboard_reset_circuit_breakers {
    return Intl.message('Reset Circuit Breakers', name: 'dashboard_reset_circuit_breakers', desc: '', args: []);
  }

  /// `Open Dynamic Forms`
  String get dashboard_open_dynamic_forms {
    return Intl.message('Open Dynamic Forms', name: 'dashboard_open_dynamic_forms', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Inactive`
  String get inactive {
    return Intl.message('Inactive', name: 'inactive', desc: '', args: []);
  }

  /// `Browse and manage users in a table view.`
  String get user_list_subtitle {
    return Intl.message('Browse and manage users in a table view.', name: 'user_list_subtitle', desc: '', args: []);
  }

  /// `Actions`
  String get user_list_actions {
    return Intl.message('Actions', name: 'user_list_actions', desc: '', args: []);
  }

  /// `Role filter`
  String get user_list_role_filter {
    return Intl.message('Role filter', name: 'user_list_role_filter', desc: '', args: []);
  }

  /// `Filter users...`
  String get user_list_search_hint {
    return Intl.message('Filter users...', name: 'user_list_search_hint', desc: '', args: []);
  }

  /// `User Information`
  String get user_editor_info_title {
    return Intl.message('User Information', name: 'user_editor_info_title', desc: '', args: []);
  }

  /// `Manage identity, contact, and access settings.`
  String get user_editor_info_description {
    return Intl.message(
      'Manage identity, contact, and access settings.',
      name: 'user_editor_info_description',
      desc: '',
      args: [],
    );
  }

  /// `Identity`
  String get user_editor_identity {
    return Intl.message('Identity', name: 'user_editor_identity', desc: '', args: []);
  }

  /// `Basic account identity details.`
  String get user_editor_identity_description {
    return Intl.message(
      'Basic account identity details.',
      name: 'user_editor_identity_description',
      desc: '',
      args: [],
    );
  }

  /// `Contact`
  String get user_editor_contact {
    return Intl.message('Contact', name: 'user_editor_contact', desc: '', args: []);
  }

  /// `Primary contact information.`
  String get user_editor_contact_description {
    return Intl.message('Primary contact information.', name: 'user_editor_contact_description', desc: '', args: []);
  }

  /// `Access`
  String get user_editor_access {
    return Intl.message('Access', name: 'user_editor_access', desc: '', args: []);
  }

  /// `Account status and role permissions.`
  String get user_editor_access_description {
    return Intl.message(
      'Account status and role permissions.',
      name: 'user_editor_access_description',
      desc: '',
      args: [],
    );
  }

  /// `Fill in the details to create a new user.`
  String get user_editor_create_subtitle {
    return Intl.message(
      'Fill in the details to create a new user.',
      name: 'user_editor_create_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Update user information below.`
  String get user_editor_edit_subtitle {
    return Intl.message('Update user information below.', name: 'user_editor_edit_subtitle', desc: '', args: []);
  }

  /// `View user details.`
  String get user_editor_view_subtitle {
    return Intl.message('View user details.', name: 'user_editor_view_subtitle', desc: '', args: []);
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Error`
  String get error_title {
    return Intl.message('Error', name: 'error_title', desc: '', args: []);
  }

  /// `Form submitted successfully`
  String get dynamic_form_submitted {
    return Intl.message('Form submitted successfully', name: 'dynamic_form_submitted', desc: '', args: []);
  }

  /// `{field} is required`
  String dynamic_form_field_required(String field) {
    return Intl.message('$field is required', name: 'dynamic_form_field_required', desc: '', args: [field]);
  }

  /// `{field} must be at least {count, plural, =1{1 character} other{{count} characters}}`
  String dynamic_form_field_min_length(String field, int count) {
    return Intl.message(
      '$field must be at least ${Intl.plural(count, one: '1 character', other: '$count characters')}',
      name: 'dynamic_form_field_min_length',
      desc: '',
      args: [field, count],
    );
  }

  /// `{field} must be at most {count, plural, =1{1 character} other{{count} characters}}`
  String dynamic_form_field_max_length(String field, int count) {
    return Intl.message(
      '$field must be at most ${Intl.plural(count, one: '1 character', other: '$count characters')}',
      name: 'dynamic_form_field_max_length',
      desc: '',
      args: [field, count],
    );
  }

  /// `Must be a number`
  String get dynamic_form_field_numeric {
    return Intl.message('Must be a number', name: 'dynamic_form_field_numeric', desc: '', args: []);
  }

  /// `Apply`
  String get apply {
    return Intl.message('Apply', name: 'apply', desc: '', args: []);
  }

  /// `Previous`
  String get previous {
    return Intl.message('Previous', name: 'previous', desc: '', args: []);
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `{count, plural, =1{1 row listed.} other{{count} rows listed.}}`
  String table_rows_listed(int count) {
    return Intl.plural(
      count,
      one: '1 row listed.',
      other: '$count rows listed.',
      name: 'table_rows_listed',
      desc: '',
      args: [count],
    );
  }

  /// `Choose Theme`
  String get theme_dialog_title {
    return Intl.message('Choose Theme', name: 'theme_dialog_title', desc: '', args: []);
  }

  /// `Select your preferred theme style`
  String get theme_dialog_subtitle {
    return Intl.message('Select your preferred theme style', name: 'theme_dialog_subtitle', desc: '', args: []);
  }

  /// `Classic`
  String get theme_palette_classic {
    return Intl.message('Classic', name: 'theme_palette_classic', desc: '', args: []);
  }

  /// `Neutral zinc, clean and minimal`
  String get theme_palette_classic_description {
    return Intl.message(
      'Neutral zinc, clean and minimal',
      name: 'theme_palette_classic_description',
      desc: '',
      args: [],
    );
  }

  /// `Nature`
  String get theme_palette_nature {
    return Intl.message('Nature', name: 'theme_palette_nature', desc: '', args: []);
  }

  /// `Sage green, calm and organic`
  String get theme_palette_nature_description {
    return Intl.message('Sage green, calm and organic', name: 'theme_palette_nature_description', desc: '', args: []);
  }

  /// `Sunset`
  String get theme_palette_sunset {
    return Intl.message('Sunset', name: 'theme_palette_sunset', desc: '', args: []);
  }

  /// `Warm stone, rich and inviting`
  String get theme_palette_sunset_description {
    return Intl.message('Warm stone, rich and inviting', name: 'theme_palette_sunset_description', desc: '', args: []);
  }

  /// `Show password`
  String get password_show {
    return Intl.message('Show password', name: 'password_show', desc: '', args: []);
  }

  /// `Hide password`
  String get password_hide {
    return Intl.message('Hide password', name: 'password_hide', desc: '', args: []);
  }

  /// `No users to show`
  String get user_list_empty {
    return Intl.message('No users to show', name: 'user_list_empty', desc: '', args: []);
  }

  /// `Flutter BLoC Advance Template`
  String get app_title {
    return Intl.message('Flutter BLoC Advance Template', name: 'app_title', desc: '', args: []);
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
