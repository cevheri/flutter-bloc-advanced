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

  static String m0(count) => "${Intl.plural(count, one: '1 item cached', other: '${count} items cached')}";

  static String m1(count) => "${Intl.plural(count, one: '1 endpoint', other: '${count} endpoints')}";

  static String m2(count) => "Failures: ${count}";

  static String m3(enabled, total) => "${enabled}/${total} enabled";

  static String m4(count) => "${count} open";

  static String m5(field, count) =>
      "${field} must be at most ${Intl.plural(count, one: '1 character', other: '${count} characters')}";

  static String m6(field, count) =>
      "${field} must be at least ${Intl.plural(count, one: '1 character', other: '${count} characters')}";

  static String m7(field) => "${field} is required";

  static String m8(url) => "Could not open ${url}";

  static String m9(currentVersion, minimumVersion) => "Current: ${currentVersion}  •  Required: ${minimumVersion}";

  static String m10(email) => "OTP sent to ${email}";

  static String m11(max) => "Password cannot be more than ${max} characters long";

  static String m12(min) => "Password must be at least ${min} characters long";

  static String m13(count) => "${Intl.plural(count, one: '1 row listed.', other: '${count} rows listed.')}";

  static String m14(translate) =>
      "${Intl.select(translate, {'account': 'Account', 'userManagement': 'User Management', 'settings': 'Settings', 'logout': 'Logout', 'info': 'Info', 'language': 'Language', 'theme': 'Theme', 'new_user': 'New', 'list_user': 'List', 'other': 'Other'})}";

  static String m15(error) => "Save failed: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "active": MessageLookupByLibrary.simpleMessage("Active"),
    "admin": MessageLookupByLibrary.simpleMessage("Admin"),
    "apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "authorities": MessageLookupByLibrary.simpleMessage("Authorities"),
    "authorities_load_failed": MessageLookupByLibrary.simpleMessage("Roles unavailable"),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "change_password": MessageLookupByLibrary.simpleMessage("Change Password"),
    "change_password_description": MessageLookupByLibrary.simpleMessage(
      "Ensure your account is using a long, random password to stay secure.",
    ),
    "command_palette_account_description": MessageLookupByLibrary.simpleMessage("Your profile"),
    "command_palette_change_password_description": MessageLookupByLibrary.simpleMessage("Update password"),
    "command_palette_hint": MessageLookupByLibrary.simpleMessage("Type a command or search..."),
    "command_palette_home_description": MessageLookupByLibrary.simpleMessage("Go to home"),
    "command_palette_new_user_description": MessageLookupByLibrary.simpleMessage("Create a new user"),
    "command_palette_no_results": MessageLookupByLibrary.simpleMessage("No results found"),
    "command_palette_settings_description": MessageLookupByLibrary.simpleMessage("App preferences"),
    "command_palette_users_description": MessageLookupByLibrary.simpleMessage("Manage users"),
    "community_contribute": MessageLookupByLibrary.simpleMessage("Contribute"),
    "community_discussions": MessageLookupByLibrary.simpleMessage("Discussions"),
    "community_docs": MessageLookupByLibrary.simpleMessage("Documentation"),
    "community_issue": MessageLookupByLibrary.simpleMessage("Open an Issue"),
    "community_open_source": MessageLookupByLibrary.simpleMessage("Open Source"),
    "community_sponsor": MessageLookupByLibrary.simpleMessage("Sponsor"),
    "community_star": MessageLookupByLibrary.simpleMessage("Star & Fork"),
    "community_subtitle": MessageLookupByLibrary.simpleMessage(
      "This project is open source. Your contributions make it better!",
    ),
    "community_title": MessageLookupByLibrary.simpleMessage("Join the Community"),
    "community_translate": MessageLookupByLibrary.simpleMessage("Translate"),
    "connectivity_offline": MessageLookupByLibrary.simpleMessage("No internet connection"),
    "create_user": MessageLookupByLibrary.simpleMessage("Create User"),
    "current_password": MessageLookupByLibrary.simpleMessage("Current Password"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "dashboard_app_configuration": MessageLookupByLibrary.simpleMessage("App Configuration"),
    "dashboard_cache": MessageLookupByLibrary.simpleMessage("Cache"),
    "dashboard_cached_item_count": m0,
    "dashboard_circuit_breaker": MessageLookupByLibrary.simpleMessage("Circuit Breaker"),
    "dashboard_circuit_breaker_health": MessageLookupByLibrary.simpleMessage("Circuit Breaker Health"),
    "dashboard_clear_cache": MessageLookupByLibrary.simpleMessage("Clear Cache"),
    "dashboard_connectivity": MessageLookupByLibrary.simpleMessage("Connectivity"),
    "dashboard_current_version": MessageLookupByLibrary.simpleMessage("Current Version"),
    "dashboard_endpoint_count": m1,
    "dashboard_environment": MessageLookupByLibrary.simpleMessage("Environment"),
    "dashboard_error_title": MessageLookupByLibrary.simpleMessage("Dashboard Error"),
    "dashboard_failure_count": m2,
    "dashboard_feature_flags": MessageLookupByLibrary.simpleMessage("Feature Flags"),
    "dashboard_feature_flags_enabled": m3,
    "dashboard_interceptor_chain": MessageLookupByLibrary.simpleMessage("Interceptor Chain"),
    "dashboard_maintenance_mode": MessageLookupByLibrary.simpleMessage("Maintenance Mode"),
    "dashboard_minimum_version": MessageLookupByLibrary.simpleMessage("Minimum Version"),
    "dashboard_no_endpoints": MessageLookupByLibrary.simpleMessage("No endpoints tracked yet"),
    "dashboard_no_feature_flags": MessageLookupByLibrary.simpleMessage("No feature flags configured"),
    "dashboard_off": MessageLookupByLibrary.simpleMessage("OFF"),
    "dashboard_offline": MessageLookupByLibrary.simpleMessage("Offline"),
    "dashboard_on": MessageLookupByLibrary.simpleMessage("ON"),
    "dashboard_online": MessageLookupByLibrary.simpleMessage("Online"),
    "dashboard_open_count": m4,
    "dashboard_open_dynamic_forms": MessageLookupByLibrary.simpleMessage("Open Dynamic Forms"),
    "dashboard_reset_circuit_breakers": MessageLookupByLibrary.simpleMessage("Reset Circuit Breakers"),
    "dashboard_title": MessageLookupByLibrary.simpleMessage("System Dashboard"),
    "delete_confirmation": MessageLookupByLibrary.simpleMessage("Are you sure you want to delete?"),
    "delete_user": MessageLookupByLibrary.simpleMessage("Delete User"),
    "dynamic_form_field_max_length": m5,
    "dynamic_form_field_min_length": m6,
    "dynamic_form_field_numeric": MessageLookupByLibrary.simpleMessage("Must be a number"),
    "dynamic_form_field_required": m7,
    "dynamic_form_submitted": MessageLookupByLibrary.simpleMessage("Form submitted successfully"),
    "dynamic_forms": MessageLookupByLibrary.simpleMessage("Dynamic Forms"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "edit_user": MessageLookupByLibrary.simpleMessage("Edit User"),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "email_pattern": MessageLookupByLibrary.simpleMessage("Email must be a valid email address"),
    "email_send": MessageLookupByLibrary.simpleMessage("Send Email"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "error_account_password_required": MessageLookupByLibrary.simpleMessage(
      "Both current and new password are required",
    ),
    "error_account_passwords_same": MessageLookupByLibrary.simpleMessage(
      "New password must be different from current password",
    ),
    "error_auth_invalid_access_token": MessageLookupByLibrary.simpleMessage("Invalid access token"),
    "error_auth_login_failed": MessageLookupByLibrary.simpleMessage("Login failed"),
    "error_auth_otp_validation": MessageLookupByLibrary.simpleMessage("OTP validation failed"),
    "error_auth_send_otp_failed": MessageLookupByLibrary.simpleMessage("Could not send the OTP code"),
    "error_auth_session_persist_failed": MessageLookupByLibrary.simpleMessage("Could not save the session"),
    "error_generic": MessageLookupByLibrary.simpleMessage("Something went wrong"),
    "error_link_open_failed": m8,
    "error_network_cert_invalid": MessageLookupByLibrary.simpleMessage(
      "The connection could not be verified as secure, so it was blocked. Try again later or on another network.",
    ),
    "error_settings_change_language_failed": MessageLookupByLibrary.simpleMessage("Could not change the language"),
    "error_title": MessageLookupByLibrary.simpleMessage("Error"),
    "error_user_cannot_delete_admin": MessageLookupByLibrary.simpleMessage("Admin user cannot be deleted"),
    "error_user_no_authorities": MessageLookupByLibrary.simpleMessage("No authorities found"),
    "failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "first_name": MessageLookupByLibrary.simpleMessage("First Name"),
    "forbidden_back_home": MessageLookupByLibrary.simpleMessage("Back to home"),
    "forbidden_message": MessageLookupByLibrary.simpleMessage("You do not have permission to view this page."),
    "forbidden_title": MessageLookupByLibrary.simpleMessage("Access denied"),
    "force_update_button": MessageLookupByLibrary.simpleMessage("Update Now"),
    "force_update_message": MessageLookupByLibrary.simpleMessage(
      "A new version is available. Please update to continue using the app.",
    ),
    "force_update_no_store_link": MessageLookupByLibrary.simpleMessage(
      "Open your app store to install the latest version.",
    ),
    "force_update_store_link_invalid": MessageLookupByLibrary.simpleMessage(
      "The update link is not valid. Open your app store to install the latest version.",
    ),
    "force_update_title": MessageLookupByLibrary.simpleMessage("Update Required"),
    "force_update_versions": m9,
    "forgot_password_description": MessageLookupByLibrary.simpleMessage(
      "Enter your email address and we\'ll send you a link to reset your password.",
    ),
    "guest": MessageLookupByLibrary.simpleMessage("Guest"),
    "help_resources": MessageLookupByLibrary.simpleMessage("Help & Resources"),
    "help_resources_subtitle": MessageLookupByLibrary.simpleMessage("Visit our website for documentation and guides"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "idle_timeout_signed_out": MessageLookupByLibrary.simpleMessage("You were signed out due to inactivity."),
    "inactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "invalid_email": MessageLookupByLibrary.simpleMessage("Invalid email address"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "language_select": MessageLookupByLibrary.simpleMessage("Select Language"),
    "last_name": MessageLookupByLibrary.simpleMessage("Last Name"),
    "list": MessageLookupByLibrary.simpleMessage("List"),
    "list_user": MessageLookupByLibrary.simpleMessage("List User"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "login_brand_description": MessageLookupByLibrary.simpleMessage(
      "Authentication, role-based access, user management,\ntheming, and multi-environment support in one robust starter.",
    ),
    "login_brand_headline": MessageLookupByLibrary.simpleMessage("Scale from prototype\nto production."),
    "login_brand_stat_bloc_ready": MessageLookupByLibrary.simpleMessage("BLoC Ready"),
    "login_brand_stat_layers": MessageLookupByLibrary.simpleMessage("Core Layers"),
    "login_brand_stat_platforms": MessageLookupByLibrary.simpleMessage("Platforms"),
    "login_button": MessageLookupByLibrary.simpleMessage("Login"),
    "login_feature_architecture_description": MessageLookupByLibrary.simpleMessage(
      "BLoC + Repository pattern with clear separation of concerns.",
    ),
    "login_feature_architecture_title": MessageLookupByLibrary.simpleMessage("Clean Architecture"),
    "login_feature_auth_description": MessageLookupByLibrary.simpleMessage(
      "Password and OTP login flows with role-based routing guards.",
    ),
    "login_feature_auth_title": MessageLookupByLibrary.simpleMessage("Authentication & Access Control"),
    "login_feature_mock_api_description": MessageLookupByLibrary.simpleMessage(
      "Develop locally with mock data and switch to production endpoints.",
    ),
    "login_feature_mock_api_title": MessageLookupByLibrary.simpleMessage("Mock to Real API"),
    "login_no_account": MessageLookupByLibrary.simpleMessage("Don\'t have an account? "),
    "login_or": MessageLookupByLibrary.simpleMessage("or"),
    "login_otp_email_instructions": MessageLookupByLibrary.simpleMessage("Enter your email to receive OTP code"),
    "login_password": MessageLookupByLibrary.simpleMessage("Password"),
    "login_switch_to_dark_mode": MessageLookupByLibrary.simpleMessage("Switch to dark mode"),
    "login_switch_to_light_mode": MessageLookupByLibrary.simpleMessage("Switch to light mode"),
    "login_user_name": MessageLookupByLibrary.simpleMessage("Username"),
    "login_welcome_subtitle": MessageLookupByLibrary.simpleMessage("Enter your credentials to access your account"),
    "login_welcome_title": MessageLookupByLibrary.simpleMessage("Welcome back"),
    "login_with_email": MessageLookupByLibrary.simpleMessage("Login with Email"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "logout_stored_data_left": MessageLookupByLibrary.simpleMessage(
      "You were signed out, but some stored data could not be removed from this device.",
    ),
    "logout_sure": MessageLookupByLibrary.simpleMessage("Are you sure you want to logout?"),
    "max_length_100": MessageLookupByLibrary.simpleMessage("Field cannot be more than 100 characters long"),
    "max_length_20": MessageLookupByLibrary.simpleMessage("Field cannot be more than 20 characters long"),
    "min_length_2": MessageLookupByLibrary.simpleMessage("Field must be at least 2 characters long"),
    "min_length_4": MessageLookupByLibrary.simpleMessage("Field must be at least 4 characters long"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "new_item": MessageLookupByLibrary.simpleMessage("New"),
    "new_password": MessageLookupByLibrary.simpleMessage("New Password"),
    "new_user": MessageLookupByLibrary.simpleMessage("New User"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "no_changes_made": MessageLookupByLibrary.simpleMessage("No changes made"),
    "no_data": MessageLookupByLibrary.simpleMessage("No Data"),
    "not_found_message": MessageLookupByLibrary.simpleMessage("The page you requested could not be found."),
    "not_found_title": MessageLookupByLibrary.simpleMessage("Page Not Found"),
    "only_numbers": MessageLookupByLibrary.simpleMessage("Only numbers are allowed"),
    "otp_code": MessageLookupByLibrary.simpleMessage("OTP Code"),
    "otp_length": MessageLookupByLibrary.simpleMessage("OTP must be 6 characters long"),
    "otp_sent_to_email": m10,
    "password_forgot": MessageLookupByLibrary.simpleMessage("Forgot Password"),
    "password_max_length": m11,
    "password_min_length": m12,
    "previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "quick_actions": MessageLookupByLibrary.simpleMessage("Quick Actions"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "register": MessageLookupByLibrary.simpleMessage("Register"),
    "register_subtitle": MessageLookupByLibrary.simpleMessage("Create your account"),
    "required_field": MessageLookupByLibrary.simpleMessage("Required Field"),
    "required_range": MessageLookupByLibrary.simpleMessage("Range is required"),
    "resend_otp_code": MessageLookupByLibrary.simpleMessage("Resend OTP Code"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "role": MessageLookupByLibrary.simpleMessage("Role"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "send_otp_code": MessageLookupByLibrary.simpleMessage("Send OTP Code"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settings_account_subtitle": MessageLookupByLibrary.simpleMessage("View or edit your profile information"),
    "settings_appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "settings_change_password_subtitle": MessageLookupByLibrary.simpleMessage("Update your password securely"),
    "settings_subtitle": MessageLookupByLibrary.simpleMessage("Manage your account preferences"),
    "settings_theme_subtitle": MessageLookupByLibrary.simpleMessage("Choose your preferred theme style"),
    "sidebar_collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
    "sidebar_expand": MessageLookupByLibrary.simpleMessage("Expand"),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "success": MessageLookupByLibrary.simpleMessage("Success"),
    "table_rows_listed": m13,
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "theme_dialog_subtitle": MessageLookupByLibrary.simpleMessage("Select your preferred theme style"),
    "theme_dialog_title": MessageLookupByLibrary.simpleMessage("Choose Theme"),
    "theme_mode_dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "theme_mode_light": MessageLookupByLibrary.simpleMessage("Light"),
    "theme_palette_classic": MessageLookupByLibrary.simpleMessage("Classic"),
    "theme_palette_classic_description": MessageLookupByLibrary.simpleMessage("Neutral zinc, clean and minimal"),
    "theme_palette_nature": MessageLookupByLibrary.simpleMessage("Nature"),
    "theme_palette_nature_description": MessageLookupByLibrary.simpleMessage("Sage green, calm and organic"),
    "theme_palette_sunset": MessageLookupByLibrary.simpleMessage("Sunset"),
    "theme_palette_sunset_description": MessageLookupByLibrary.simpleMessage("Warm stone, rich and inviting"),
    "translate_menu_title": m14,
    "turkish": MessageLookupByLibrary.simpleMessage("Turkish"),
    "unsaved_changes": MessageLookupByLibrary.simpleMessage(
      "You have unsaved changes. Are you sure you want to leave?",
    ),
    "user_delete_failed": MessageLookupByLibrary.simpleMessage("Could not delete the user"),
    "user_editor_access": MessageLookupByLibrary.simpleMessage("Access"),
    "user_editor_access_description": MessageLookupByLibrary.simpleMessage("Account status and role permissions."),
    "user_editor_contact": MessageLookupByLibrary.simpleMessage("Contact"),
    "user_editor_contact_description": MessageLookupByLibrary.simpleMessage("Primary contact information."),
    "user_editor_create_subtitle": MessageLookupByLibrary.simpleMessage("Fill in the details to create a new user."),
    "user_editor_edit_subtitle": MessageLookupByLibrary.simpleMessage("Update user information below."),
    "user_editor_identity": MessageLookupByLibrary.simpleMessage("Identity"),
    "user_editor_identity_description": MessageLookupByLibrary.simpleMessage("Basic account identity details."),
    "user_editor_info_description": MessageLookupByLibrary.simpleMessage(
      "Manage identity, contact, and access settings.",
    ),
    "user_editor_info_title": MessageLookupByLibrary.simpleMessage("User Information"),
    "user_editor_view_subtitle": MessageLookupByLibrary.simpleMessage("View user details."),
    "user_extended_info_button": MessageLookupByLibrary.simpleMessage("Extended Info"),
    "user_extended_info_save_failed": m15,
    "user_extended_info_saved": MessageLookupByLibrary.simpleMessage("Saved"),
    "user_extended_info_title": MessageLookupByLibrary.simpleMessage("Extended Information"),
    "user_list_actions": MessageLookupByLibrary.simpleMessage("Actions"),
    "user_list_load_failed": MessageLookupByLibrary.simpleMessage("Could not load the users"),
    "user_list_role_filter": MessageLookupByLibrary.simpleMessage("Role filter"),
    "user_list_search_hint": MessageLookupByLibrary.simpleMessage("Filter users..."),
    "user_list_subtitle": MessageLookupByLibrary.simpleMessage("Browse and manage users in a table view."),
    "user_load_failed": MessageLookupByLibrary.simpleMessage("Could not load the user"),
    "users": MessageLookupByLibrary.simpleMessage("Users"),
    "verify_otp_code": MessageLookupByLibrary.simpleMessage("Verify OTP Code"),
    "view_user": MessageLookupByLibrary.simpleMessage("View User"),
    "warning": MessageLookupByLibrary.simpleMessage("Warning"),
    "website": MessageLookupByLibrary.simpleMessage("Website"),
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
  };
}
