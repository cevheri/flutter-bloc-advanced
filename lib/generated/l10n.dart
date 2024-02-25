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

  /// `Account`
  String get account {
    return Intl.message(
      'Account',
      name: 'account',
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

  /// `Address`
  String get address {
    return Intl.message(
      'Address',
      name: 'address',
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

  /// `Approved`
  String get approved_status {
    return Intl.message(
      'Approved',
      name: 'approved_status',
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

  /// `Authorities is required`
  String get authorities_required {
    return Intl.message(
      'Authorities is required',
      name: 'authorities_required',
      desc: '',
      args: [],
    );
  }

  /// `birim`
  String get birim {
    return Intl.message(
      'birim',
      name: 'birim',
      desc: '',
      args: [],
    );
  }

  /// `birim must be a valid`
  String get birim_numeric {
    return Intl.message(
      'birim must be a valid',
      name: 'birim_numeric',
      desc: '',
      args: [],
    );
  }

  /// `birim is required`
  String get birim_required {
    return Intl.message(
      'birim is required',
      name: 'birim_required',
      desc: '',
      args: [],
    );
  }

  /// `Calculate`
  String get calculate {
    return Intl.message(
      'Calculate',
      name: 'calculate',
      desc: '',
      args: [],
    );
  }

  /// `Calculated Maturity`
  String get calculated_maturity_screen {
    return Intl.message(
      'Calculated Maturity',
      name: 'calculated_maturity_screen',
      desc: '',
      args: [],
    );
  }

  /// `Calculated`
  String get calculated_status {
    return Intl.message(
      'Calculated',
      name: 'calculated_status',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get cancelled_status {
    return Intl.message(
      'Cancelled',
      name: 'cancelled_status',
      desc: '',
      args: [],
    );
  }

  /// `Account Code`
  String get cari_kod {
    return Intl.message(
      'Account Code',
      name: 'cari_kod',
      desc: '',
      args: [],
    );
  }

  /// `Change Password`
  String get change {
    return Intl.message(
      'Change Password',
      name: 'change',
      desc: '',
      args: [],
    );
  }

  /// `Nothing changed`
  String get change_nothing {
    return Intl.message(
      'Nothing changed',
      name: 'change_nothing',
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

  /// `Cities`
  String get cities {
    return Intl.message(
      'Cities',
      name: 'cities',
      desc: '',
      args: [],
    );
  }

  /// `City`
  String get city {
    return Intl.message(
      'City',
      name: 'city',
      desc: '',
      args: [],
    );
  }

  /// `City is required`
  String get city_required {
    return Intl.message(
      'City is required',
      name: 'city_required',
      desc: '',
      args: [],
    );
  }

  /// `Code`
  String get code {
    return Intl.message(
      'Code',
      name: 'code',
      desc: '',
      args: [],
    );
  }

  /// `Company Name`
  String get company_name {
    return Intl.message(
      'Company Name',
      name: 'company_name',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get completed_status {
    return Intl.message(
      'Completed',
      name: 'completed_status',
      desc: '',
      args: [],
    );
  }

  /// `Passwords must match`
  String get confirm {
    return Intl.message(
      'Passwords must match',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Confirm New Password`
  String get confirm_new {
    return Intl.message(
      'Confirm New Password',
      name: 'confirm_new',
      desc: '',
      args: [],
    );
  }

  /// `Confirmation Offers`
  String get confirmation_status {
    return Intl.message(
      'Confirmation Offers',
      name: 'confirmation_status',
      desc: '',
      args: [],
    );
  }

  /// `Corporation`
  String get corporation {
    return Intl.message(
      'Corporation',
      name: 'corporation',
      desc: '',
      args: [],
    );
  }

  /// `Corporation is required`
  String get corporation_required {
    return Intl.message(
      'Corporation is required',
      name: 'corporation_required',
      desc: '',
      args: [],
    );
  }

  /// `Corporations`
  String get corporations {
    return Intl.message(
      'Corporations',
      name: 'corporations',
      desc: '',
      args: [],
    );
  }

  /// `Cost`
  String get cost {
    return Intl.message(
      'Cost',
      name: 'cost',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get create {
    return Intl.message(
      'Create',
      name: 'create',
      desc: '',
      args: [],
    );
  }

  /// `Create New Offer`
  String get createNewOffer {
    return Intl.message(
      'Create New Offer',
      name: 'createNewOffer',
      desc: '',
      args: [],
    );
  }

  /// `Create Corporation`
  String get create_corporation {
    return Intl.message(
      'Create Corporation',
      name: 'create_corporation',
      desc: '',
      args: [],
    );
  }

  /// `Create Corporation Maturity`
  String get create_corporation_maturity {
    return Intl.message(
      'Create Corporation Maturity',
      name: 'create_corporation_maturity',
      desc: '',
      args: [],
    );
  }

  /// `Create Offer`
  String get create_offer {
    return Intl.message(
      'Create Offer',
      name: 'create_offer',
      desc: '',
      args: [],
    );
  }

  /// `Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!`
  String get create_record_error {
    return Intl.message(
      'Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!',
      name: 'create_record_error',
      desc: '',
      args: [],
    );
  }

  /// `Create Refinery`
  String get create_refinery {
    return Intl.message(
      'Create Refinery',
      name: 'create_refinery',
      desc: '',
      args: [],
    );
  }

  /// `Create Station`
  String get create_station {
    return Intl.message(
      'Create Station',
      name: 'create_station',
      desc: '',
      args: [],
    );
  }

  /// `Create Station Maturity`
  String get create_station_maturity {
    return Intl.message(
      'Create Station Maturity',
      name: 'create_station_maturity',
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

  /// `Credit`
  String get credit {
    return Intl.message(
      'Credit',
      name: 'credit',
      desc: '',
      args: [],
    );
  }

  /// `Credit Card`
  String get credit_card {
    return Intl.message(
      'Credit Card',
      name: 'credit_card',
      desc: '',
      args: [],
    );
  }

  /// `Current Password`
  String get currentPassword {
    return Intl.message(
      'Current Password',
      name: 'currentPassword',
      desc: '',
      args: [],
    );
  }

  /// `Customer`
  String get customer {
    return Intl.message(
      'Customer',
      name: 'customer',
      desc: '',
      args: [],
    );
  }

  /// `Customers`
  String get customers {
    return Intl.message(
      'Customers',
      name: 'customers',
      desc: '',
      args: [],
    );
  }

  /// `Daily`
  String get daily {
    return Intl.message(
      'Daily',
      name: 'daily',
      desc: '',
      args: [],
    );
  }

  /// `Dark/Light Mode`
  String get darkLight {
    return Intl.message(
      'Dark/Light Mode',
      name: 'darkLight',
      desc: '',
      args: [],
    );
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message(
      'Dashboard',
      name: 'dashboard',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get date {
    return Intl.message(
      'Date',
      name: 'date',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get day {
    return Intl.message(
      'Day',
      name: 'day',
      desc: '',
      args: [],
    );
  }

  /// `Debt`
  String get debt {
    return Intl.message(
      'Debt',
      name: 'debt',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete?`
  String get delete_confirmation {
    return Intl.message(
      'Are you sure you want to delete?',
      name: 'delete_confirmation',
      desc: '',
      args: [],
    );
  }

  /// `CRM`
  String get description {
    return Intl.message(
      'CRM',
      name: 'description',
      desc: '',
      args: [],
    );
  }

  /// `Description cannot be more than 20 characters long`
  String get description_max_length {
    return Intl.message(
      'Description cannot be more than 20 characters long',
      name: 'description_max_length',
      desc: '',
      args: [],
    );
  }

  /// `Description must be at least 5 characters long`
  String get description_min_length {
    return Intl.message(
      'Description must be at least 5 characters long',
      name: 'description_min_length',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description_offer {
    return Intl.message(
      'Description',
      name: 'description_offer',
      desc: '',
      args: [],
    );
  }

  /// `Description must be a valid`
  String get description_regex_pattern {
    return Intl.message(
      'Description must be a valid',
      name: 'description_regex_pattern',
      desc: '',
      args: [],
    );
  }

  /// `Description is required`
  String get description_required {
    return Intl.message(
      'Description is required',
      name: 'description_required',
      desc: '',
      args: [],
    );
  }

  /// `Destination Address`
  String get destination_address {
    return Intl.message(
      'Destination Address',
      name: 'destination_address',
      desc: '',
      args: [],
    );
  }

  /// `Destination City`
  String get destination_city {
    return Intl.message(
      'Destination City',
      name: 'destination_city',
      desc: '',
      args: [],
    );
  }

  /// `Destination City is required`
  String get destination_city_required {
    return Intl.message(
      'Destination City is required',
      name: 'destination_city_required',
      desc: '',
      args: [],
    );
  }

  /// `Destination District`
  String get destination_district {
    return Intl.message(
      'Destination District',
      name: 'destination_district',
      desc: '',
      args: [],
    );
  }

  /// `Detail`
  String get detail {
    return Intl.message(
      'Detail',
      name: 'detail',
      desc: '',
      args: [],
    );
  }

  /// `District`
  String get district {
    return Intl.message(
      'District',
      name: 'district',
      desc: '',
      args: [],
    );
  }

  /// `Districts`
  String get districts {
    return Intl.message(
      'Districts',
      name: 'districts',
      desc: '',
      args: [],
    );
  }

  /// `Document`
  String get document {
    return Intl.message(
      'Document',
      name: 'document',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Edit Corporation`
  String get edit_corporation {
    return Intl.message(
      'Edit Corporation',
      name: 'edit_corporation',
      desc: '',
      args: [],
    );
  }

  /// `Edit Corporation Maturity`
  String get edit_corporation_maturity {
    return Intl.message(
      'Edit Corporation Maturity',
      name: 'edit_corporation_maturity',
      desc: '',
      args: [],
    );
  }

  /// `Edit Offer`
  String get edit_offer {
    return Intl.message(
      'Edit Offer',
      name: 'edit_offer',
      desc: '',
      args: [],
    );
  }

  /// `Edit Refinery`
  String get edit_refinery {
    return Intl.message(
      'Edit Refinery',
      name: 'edit_refinery',
      desc: '',
      args: [],
    );
  }

  /// `Edit Station`
  String get edit_station {
    return Intl.message(
      'Edit Station',
      name: 'edit_station',
      desc: '',
      args: [],
    );
  }

  /// `Edit Station Maturity`
  String get edit_station_maturity {
    return Intl.message(
      'Edit Station Maturity',
      name: 'edit_station_maturity',
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

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Email address not found`
  String get email_error {
    return Intl.message(
      'Email address not found',
      name: 'email_error',
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

  /// `Email is required`
  String get email_required {
    return Intl.message(
      'Email is required',
      name: 'email_required',
      desc: '',
      args: [],
    );
  }

  /// `Email address not found`
  String get email_reset_password_error {
    return Intl.message(
      'Email address not found',
      name: 'email_reset_password_error',
      desc: '',
      args: [],
    );
  }

  /// `Sending email to reset password...`
  String get email_reset_password_sending {
    return Intl.message(
      'Sending email to reset password...',
      name: 'email_reset_password_sending',
      desc: '',
      args: [],
    );
  }

  /// `Email sent successfully`
  String get email_reset_password_success {
    return Intl.message(
      'Email sent successfully',
      name: 'email_reset_password_success',
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

  /// `Email sent successfully`
  String get email_success {
    return Intl.message(
      'Email sent successfully',
      name: 'email_success',
      desc: '',
      args: [],
    );
  }

  /// `Password cannot be left blank`
  String get empty {
    return Intl.message(
      'Password cannot be left blank',
      name: 'empty',
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

  /// `Email address not found`
  String get error {
    return Intl.message(
      'Email address not found',
      name: 'error',
      desc: '',
      args: [],
    );
  }

  /// `Exit`
  String get exit {
    return Intl.message(
      'Exit',
      name: 'exit',
      desc: '',
      args: [],
    );
  }

  /// ` Find `
  String get find {
    return Intl.message(
      ' Find ',
      name: 'find',
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

  /// `Firstname cannot be more than 20 characters long`
  String get firstname_max_length {
    return Intl.message(
      'Firstname cannot be more than 20 characters long',
      name: 'firstname_max_length',
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

  /// `Firstname is required`
  String get firstname_required {
    return Intl.message(
      'Firstname is required',
      name: 'firstname_required',
      desc: '',
      args: [],
    );
  }

  /// `Forgot Password`
  String get forgot {
    return Intl.message(
      'Forgot Password',
      name: 'forgot',
      desc: '',
      args: [],
    );
  }

  /// `CRM`
  String get global {
    return Intl.message(
      'CRM',
      name: 'global',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message(
      'Home',
      name: 'home',
      desc: '',
      args: [],
    );
  }

  /// `Home Page`
  String get home_page {
    return Intl.message(
      'Home Page',
      name: 'home_page',
      desc: '',
      args: [],
    );
  }

  /// `Bad Request`
  String get http_400 {
    return Intl.message(
      'Bad Request',
      name: 'http_400',
      desc: '',
      args: [],
    );
  }

  /// `Unauthorized`
  String get http_401 {
    return Intl.message(
      'Unauthorized',
      name: 'http_401',
      desc: '',
      args: [],
    );
  }

  /// `Payment Required`
  String get http_402 {
    return Intl.message(
      'Payment Required',
      name: 'http_402',
      desc: '',
      args: [],
    );
  }

  /// `Forbidden`
  String get http_403 {
    return Intl.message(
      'Forbidden',
      name: 'http_403',
      desc: '',
      args: [],
    );
  }

  /// `Not Found`
  String get http_404 {
    return Intl.message(
      'Not Found',
      name: 'http_404',
      desc: '',
      args: [],
    );
  }

  /// `Method Not Allowed`
  String get http_405 {
    return Intl.message(
      'Method Not Allowed',
      name: 'http_405',
      desc: '',
      args: [],
    );
  }

  /// `Not Acceptable`
  String get http_406 {
    return Intl.message(
      'Not Acceptable',
      name: 'http_406',
      desc: '',
      args: [],
    );
  }

  /// `Proxy Authentication Required`
  String get http_407 {
    return Intl.message(
      'Proxy Authentication Required',
      name: 'http_407',
      desc: '',
      args: [],
    );
  }

  /// `Request Timeout`
  String get http_408 {
    return Intl.message(
      'Request Timeout',
      name: 'http_408',
      desc: '',
      args: [],
    );
  }

  /// `Conflict`
  String get http_409 {
    return Intl.message(
      'Conflict',
      name: 'http_409',
      desc: '',
      args: [],
    );
  }

  /// `Gone`
  String get http_410 {
    return Intl.message(
      'Gone',
      name: 'http_410',
      desc: '',
      args: [],
    );
  }

  /// `Length Required`
  String get http_411 {
    return Intl.message(
      'Length Required',
      name: 'http_411',
      desc: '',
      args: [],
    );
  }

  /// `Precondition Failed`
  String get http_412 {
    return Intl.message(
      'Precondition Failed',
      name: 'http_412',
      desc: '',
      args: [],
    );
  }

  /// `Payload Too Large`
  String get http_413 {
    return Intl.message(
      'Payload Too Large',
      name: 'http_413',
      desc: '',
      args: [],
    );
  }

  /// `URI Too Long`
  String get http_414 {
    return Intl.message(
      'URI Too Long',
      name: 'http_414',
      desc: '',
      args: [],
    );
  }

  /// `Unsupported Media Type`
  String get http_415 {
    return Intl.message(
      'Unsupported Media Type',
      name: 'http_415',
      desc: '',
      args: [],
    );
  }

  /// `Range Not Satisfiable`
  String get http_416 {
    return Intl.message(
      'Range Not Satisfiable',
      name: 'http_416',
      desc: '',
      args: [],
    );
  }

  /// `Expectation Failed`
  String get http_417 {
    return Intl.message(
      'Expectation Failed',
      name: 'http_417',
      desc: '',
      args: [],
    );
  }

  /// `Unprocessable Entity`
  String get http_422 {
    return Intl.message(
      'Unprocessable Entity',
      name: 'http_422',
      desc: '',
      args: [],
    );
  }

  /// `Too Early`
  String get http_425 {
    return Intl.message(
      'Too Early',
      name: 'http_425',
      desc: '',
      args: [],
    );
  }

  /// `Upgrade Required`
  String get http_426 {
    return Intl.message(
      'Upgrade Required',
      name: 'http_426',
      desc: '',
      args: [],
    );
  }

  /// `Precondition Required`
  String get http_428 {
    return Intl.message(
      'Precondition Required',
      name: 'http_428',
      desc: '',
      args: [],
    );
  }

  /// `Too Many Requests`
  String get http_429 {
    return Intl.message(
      'Too Many Requests',
      name: 'http_429',
      desc: '',
      args: [],
    );
  }

  /// `Request Header Fields Too Large`
  String get http_431 {
    return Intl.message(
      'Request Header Fields Too Large',
      name: 'http_431',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable For Legal Reasons`
  String get http_451 {
    return Intl.message(
      'Unavailable For Legal Reasons',
      name: 'http_451',
      desc: '',
      args: [],
    );
  }

  /// `Internal Server Error`
  String get http_500 {
    return Intl.message(
      'Internal Server Error',
      name: 'http_500',
      desc: '',
      args: [],
    );
  }

  /// `ID`
  String get id {
    return Intl.message(
      'ID',
      name: 'id',
      desc: '',
      args: [],
    );
  }

  /// `Increase`
  String get increase {
    return Intl.message(
      'Increase',
      name: 'increase',
      desc: '',
      args: [],
    );
  }

  /// `Increase Price`
  String get increase_unit_price {
    return Intl.message(
      'Increase Price',
      name: 'increase_unit_price',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get indicator {
    return Intl.message(
      'Loading...',
      name: 'indicator',
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

  /// `Last Name`
  String get last_name {
    return Intl.message(
      'Last Name',
      name: 'last_name',
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

  /// `Lastname must be at least 5 characters long`
  String get lastname_min_length {
    return Intl.message(
      'Lastname must be at least 5 characters long',
      name: 'lastname_min_length',
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

  /// `List`
  String get list {
    return Intl.message(
      'List',
      name: 'list',
      desc: '',
      args: [],
    );
  }

  /// `List Offer`
  String get listOffer {
    return Intl.message(
      'List Offer',
      name: 'listOffer',
      desc: '',
      args: [],
    );
  }

  /// `List Corporation`
  String get list_corporation {
    return Intl.message(
      'List Corporation',
      name: 'list_corporation',
      desc: '',
      args: [],
    );
  }

  /// `List Offer`
  String get list_offer {
    return Intl.message(
      'List Offer',
      name: 'list_offer',
      desc: '',
      args: [],
    );
  }

  /// `List Refinery`
  String get list_refinery {
    return Intl.message(
      'List Refinery',
      name: 'list_refinery',
      desc: '',
      args: [],
    );
  }

  /// `List Station`
  String get list_station {
    return Intl.message(
      'List Station',
      name: 'list_station',
      desc: '',
      args: [],
    );
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

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Logging in...`
  String get logging_in {
    return Intl.message(
      'Logging in...',
      name: 'logging_in',
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

  /// `Login`
  String get login_button {
    return Intl.message(
      'Login',
      name: 'login_button',
      desc: '',
      args: [],
    );
  }

  /// `Login failed.`
  String get login_error {
    return Intl.message(
      'Login failed.',
      name: 'login_error',
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

  /// `Username`
  String get login_user_name {
    return Intl.message(
      'Username',
      name: 'login_user_name',
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

  /// `Maturity`
  String get maturity {
    return Intl.message(
      'Maturity',
      name: 'maturity',
      desc: '',
      args: [],
    );
  }

  /// `Maturity Type`
  String get maturity_type {
    return Intl.message(
      'Maturity Type',
      name: 'maturity_type',
      desc: '',
      args: [],
    );
  }

  /// `Maturity Types`
  String get maturity_types {
    return Intl.message(
      'Maturity Types',
      name: 'maturity_types',
      desc: '',
      args: [],
    );
  }

  /// `Menu`
  String get menu {
    return Intl.message(
      'Menu',
      name: 'menu',
      desc: '',
      args: [],
    );
  }

  /// `Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!`
  String get messages {
    return Intl.message(
      'Kayıt Oluşturulamadı. Bilgileri kontrol ediniz.!',
      name: 'messages',
      desc: '',
      args: [],
    );
  }

  /// `Monthly`
  String get monthly {
    return Intl.message(
      'Monthly',
      name: 'monthly',
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

  /// `Name cannot be more than 20 characters long`
  String get name_max_length {
    return Intl.message(
      'Name cannot be more than 20 characters long',
      name: 'name_max_length',
      desc: '',
      args: [],
    );
  }

  /// `Name must be at least 5 characters long`
  String get name_min_length {
    return Intl.message(
      'Name must be at least 5 characters long',
      name: 'name_min_length',
      desc: '',
      args: [],
    );
  }

  /// `Name must be a valid`
  String get name_regex_pattern {
    return Intl.message(
      'Name must be a valid',
      name: 'name_regex_pattern',
      desc: '',
      args: [],
    );
  }

  /// `Name is required`
  String get name_required {
    return Intl.message(
      'Name is required',
      name: 'name_required',
      desc: '',
      args: [],
    );
  }

  /// `New Increase`
  String get new_increase {
    return Intl.message(
      'New Increase',
      name: 'new_increase',
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

  /// `Passwords do not match`
  String get not_match {
    return Intl.message(
      'Passwords do not match',
      name: 'not_match',
      desc: '',
      args: [],
    );
  }

  /// `Offer Form`
  String get offer_form {
    return Intl.message(
      'Offer Form',
      name: 'offer_form',
      desc: '',
      args: [],
    );
  }

  /// `Offers`
  String get offers {
    return Intl.message(
      'Offers',
      name: 'offers',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get ok {
    return Intl.message(
      'Ok',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
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

  /// `New Password`
  String get password_new {
    return Intl.message(
      'New Password',
      name: 'password_new',
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

  /// `Password changed successfully`
  String get password_success {
    return Intl.message(
      'Password changed successfully',
      name: 'password_success',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get phone {
    return Intl.message(
      'Phone',
      name: 'phone',
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

  /// `Plasiyer`
  String get plasiyer {
    return Intl.message(
      'Plasiyer',
      name: 'plasiyer',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get price {
    return Intl.message(
      'Price',
      name: 'price',
      desc: '',
      args: [],
    );
  }

  /// `Price cannot be empty`
  String get price_empty {
    return Intl.message(
      'Price cannot be empty',
      name: 'price_empty',
      desc: '',
      args: [],
    );
  }

  /// `Price cannot be more than 10 characters long`
  String get price_max_length {
    return Intl.message(
      'Price cannot be more than 10 characters long',
      name: 'price_max_length',
      desc: '',
      args: [],
    );
  }

  /// `Price must be at least 1 characters long`
  String get price_min_length {
    return Intl.message(
      'Price must be at least 1 characters long',
      name: 'price_min_length',
      desc: '',
      args: [],
    );
  }

  /// `Price must be a valid`
  String get price_regex_pattern {
    return Intl.message(
      'Price must be a valid',
      name: 'price_regex_pattern',
      desc: '',
      args: [],
    );
  }

  /// `Price is required`
  String get price_required {
    return Intl.message(
      'Price is required',
      name: 'price_required',
      desc: '',
      args: [],
    );
  }

  /// `With Wat Price`
  String get price_with_vat {
    return Intl.message(
      'With Wat Price',
      name: 'price_with_vat',
      desc: '',
      args: [],
    );
  }

  /// `With Wat Price cannot be empty`
  String get price_with_vat_empty {
    return Intl.message(
      'With Wat Price cannot be empty',
      name: 'price_with_vat_empty',
      desc: '',
      args: [],
    );
  }

  /// `With Wat Price cannot be more than 10 characters long`
  String get price_with_vat_max_length {
    return Intl.message(
      'With Wat Price cannot be more than 10 characters long',
      name: 'price_with_vat_max_length',
      desc: '',
      args: [],
    );
  }

  /// `With Wat Price must be at least 1 characters long`
  String get price_with_vat_min_length {
    return Intl.message(
      'With Wat Price must be at least 1 characters long',
      name: 'price_with_vat_min_length',
      desc: '',
      args: [],
    );
  }

  /// `With Wat Price must be a valid`
  String get price_with_vat_regex_pattern {
    return Intl.message(
      'With Wat Price must be a valid',
      name: 'price_with_vat_regex_pattern',
      desc: '',
      args: [],
    );
  }

  /// `With Wat Price is required`
  String get price_with_vat_required {
    return Intl.message(
      'With Wat Price is required',
      name: 'price_with_vat_required',
      desc: '',
      args: [],
    );
  }

  /// `Range`
  String get range {
    return Intl.message(
      'Range',
      name: 'range',
      desc: '',
      args: [],
    );
  }

  /// `Rate`
  String get rate {
    return Intl.message(
      'Rate',
      name: 'rate',
      desc: '',
      args: [],
    );
  }

  /// `Refineries`
  String get refineries {
    return Intl.message(
      'Refineries',
      name: 'refineries',
      desc: '',
      args: [],
    );
  }

  /// `Refineries Description`
  String get refineries_description {
    return Intl.message(
      'Refineries Description',
      name: 'refineries_description',
      desc: '',
      args: [],
    );
  }

  /// `Refinery`
  String get refinery {
    return Intl.message(
      'Refinery',
      name: 'refinery',
      desc: '',
      args: [],
    );
  }

  /// `Refinery is required`
  String get refinery_required {
    return Intl.message(
      'Refinery is required',
      name: 'refinery_required',
      desc: '',
      args: [],
    );
  }

  /// `Rejected`
  String get rejected_status {
    return Intl.message(
      'Rejected',
      name: 'rejected_status',
      desc: '',
      args: [],
    );
  }

  /// `Reports`
  String get reports {
    return Intl.message(
      'Reports',
      name: 'reports',
      desc: '',
      args: [],
    );
  }

  /// `Cost is required`
  String get required_cost {
    return Intl.message(
      'Cost is required',
      name: 'required_cost',
      desc: '',
      args: [],
    );
  }

  /// `Maturity is required`
  String get required_maturity {
    return Intl.message(
      'Maturity is required',
      name: 'required_maturity',
      desc: '',
      args: [],
    );
  }

  /// `Phone Type Required 5** *** ** ** `
  String get required_phone_type {
    return Intl.message(
      'Phone Type Required 5** *** ** ** ',
      name: 'required_phone_type',
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

  /// `Rate is required`
  String get required_rate {
    return Intl.message(
      'Rate is required',
      name: 'required_rate',
      desc: '',
      args: [],
    );
  }

  /// `Sales Person is required`
  String get required_salesPerson {
    return Intl.message(
      'Sales Person is required',
      name: 'required_salesPerson',
      desc: '',
      args: [],
    );
  }

  /// `Reset Email Address Password`
  String get reset {
    return Intl.message(
      'Reset Email Address Password',
      name: 'reset',
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

  /// `Sales Person`
  String get salesPerson {
    return Intl.message(
      'Sales Person',
      name: 'salesPerson',
      desc: '',
      args: [],
    );
  }

  /// `Sales Person Code`
  String get sales_person_code {
    return Intl.message(
      'Sales Person Code',
      name: 'sales_person_code',
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

  /// `Screen size is too small.`
  String get screen_size_error {
    return Intl.message(
      'Screen size is too small.',
      name: 'screen_size_error',
      desc: '',
      args: [],
    );
  }

  /// `Select`
  String get select {
    return Intl.message(
      'Select',
      name: 'select',
      desc: '',
      args: [],
    );
  }

  /// `Select Customer`
  String get select_customer {
    return Intl.message(
      'Select Customer',
      name: 'select_customer',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get send {
    return Intl.message(
      'Send',
      name: 'send',
      desc: '',
      args: [],
    );
  }

  /// `Send Offer`
  String get send_offer {
    return Intl.message(
      'Send Offer',
      name: 'send_offer',
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

  /// `Station`
  String get station {
    return Intl.message(
      'Station',
      name: 'station',
      desc: '',
      args: [],
    );
  }

  /// `Station Rate`
  String get station_rate {
    return Intl.message(
      'Station Rate',
      name: 'station_rate',
      desc: '',
      args: [],
    );
  }

  /// `Station is required`
  String get station_required {
    return Intl.message(
      'Station is required',
      name: 'station_required',
      desc: '',
      args: [],
    );
  }

  /// `Stations`
  String get stations {
    return Intl.message(
      'Stations',
      name: 'stations',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message(
      'Status',
      name: 'status',
      desc: '',
      args: [],
    );
  }

  /// `Password reset successfully`
  String get success {
    return Intl.message(
      'Password reset successfully',
      name: 'success',
      desc: '',
      args: [],
    );
  }

  /// `Tax Number`
  String get tax_number {
    return Intl.message(
      'Tax Number',
      name: 'tax_number',
      desc: '',
      args: [],
    );
  }

  /// `Tax Office`
  String get tax_office {
    return Intl.message(
      'Tax Office',
      name: 'tax_office',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message(
      'Theme',
      name: 'theme',
      desc: '',
      args: [],
    );
  }

  /// `Sekoya`
  String get title {
    return Intl.message(
      'Sekoya',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Todo List`
  String get todoList {
    return Intl.message(
      'Todo List',
      name: 'todoList',
      desc: '',
      args: [],
    );
  }

  /// `Total Price`
  String get total_price {
    return Intl.message(
      'Total Price',
      name: 'total_price',
      desc: '',
      args: [],
    );
  }

  /// `{translate, select, station{Stations} maturityCalculate{Maturity Calculated} stationMaturity{Station Maturity} corporation{Corporations} corporationMaturity{Corporation Maturity} refinery{Refineries} offer{Offers} customer{Customers} salesPerson{Sales Person} account{Account} settings{Settings} dashboard{Dashboard}reports{Reports} logout{Logout}  info{Info} language{Language}  theme{Theme}  create{Create}  list{List/Edit} other{Other}}`
  String translate_menu_title(Object translate) {
    return Intl.select(
      translate,
      {
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
      },
      name: 'translate_menu_title',
      desc: '',
      args: [translate],
    );
  }

  /// `{translate, select,selected{All}  CALCULATED{Hesaplanan Teklif} APPROVAL_IN_PROGRESS{Teklif Onay} TO_BE_ORDERED{Teklif onaylandı} APPROVAL_REJECTED{Teklif reddedildi} IN_NEGOTIATION{Güncel teklif müşteriye önerildi} ACCEPTED{Güncel teklifi müşteri kabul etti} RESCINDED{Güncel teklifi müşteri red etti} SHIPPED{Tamamlandı} CANCELLED{Teklif geri çekildi ve iptal edildi}  DRAFT{Kaydet} APPROVED{Teklif müşteriye gönderilmeye hazır} ORDERED{Sipariş hazırlandı} other{Diğer}}`
  String translate_status_title(Object translate) {
    return Intl.select(
      translate,
      {
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
      },
      name: 'translate_status_title',
      desc: '',
      args: [translate],
    );
  }

  /// `Transport Cost TL`
  String get transport_cost {
    return Intl.message(
      'Transport Cost TL',
      name: 'transport_cost',
      desc: '',
      args: [],
    );
  }

  /// `Transport Cost must be a valid`
  String get transport_cost_numeric {
    return Intl.message(
      'Transport Cost must be a valid',
      name: 'transport_cost_numeric',
      desc: '',
      args: [],
    );
  }

  /// `Transport Cost is required`
  String get transport_cost_required {
    return Intl.message(
      'Transport Cost is required',
      name: 'transport_cost_required',
      desc: '',
      args: [],
    );
  }

  /// `Transport`
  String get transport_cost_tl {
    return Intl.message(
      'Transport',
      name: 'transport_cost_tl',
      desc: '',
      args: [],
    );
  }

  /// `Transport Date`
  String get transport_date {
    return Intl.message(
      'Transport Date',
      name: 'transport_date',
      desc: '',
      args: [],
    );
  }

  /// `Transport Date is required`
  String get transport_date_required {
    return Intl.message(
      'Transport Date is required',
      name: 'transport_date_required',
      desc: '',
      args: [],
    );
  }

  /// `Transport Distance Km`
  String get transport_distance {
    return Intl.message(
      'Transport Distance Km',
      name: 'transport_distance',
      desc: '',
      args: [],
    );
  }

  /// `Transport Distance must be a valid`
  String get transport_distance_numeric {
    return Intl.message(
      'Transport Distance must be a valid',
      name: 'transport_distance_numeric',
      desc: '',
      args: [],
    );
  }

  /// `Transport Distance is required`
  String get transport_distance_required {
    return Intl.message(
      'Transport Distance is required',
      name: 'transport_distance_required',
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

  /// `Unit Price`
  String get unit_price {
    return Intl.message(
      'Unit Price',
      name: 'unit_price',
      desc: '',
      args: [],
    );
  }

  /// `Last Price Update`
  String get unit_price_update {
    return Intl.message(
      'Last Price Update',
      name: 'unit_price_update',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get update {
    return Intl.message(
      'Update',
      name: 'update',
      desc: '',
      args: [],
    );
  }

  /// `Update Description`
  String get update_description {
    return Intl.message(
      'Update Description',
      name: 'update_description',
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

  /// `Username is required`
  String get username_required {
    return Intl.message(
      'Username is required',
      name: 'username_required',
      desc: '',
      args: [],
    );
  }

  /// `Users`
  String get users {
    return Intl.message(
      'Users',
      name: 'users',
      desc: '',
      args: [],
    );
  }

  /// `Vat No`
  String get vat_no {
    return Intl.message(
      'Vat No',
      name: 'vat_no',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get weekly {
    return Intl.message(
      'Weekly',
      name: 'weekly',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get welcome {
    return Intl.message(
      'Welcome',
      name: 'welcome',
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

  /// `Services`
  String get services {
    return Intl.message(
      'Services',
      name: 'services',
      desc: '',
      args: [],
    );
  }

  /// `Our company, established in 2024, develops customized systems for factories by integrating advanced technologies such as industrial IoT (Internet of Things), Machine Learning, and Artificial Intelligence. These systems help our customers optimize their production processes, reduce costs, and increase efficiency. Additionally, we further enhance factory operations through our mobile application and web-based solutions.`
  String get services_detail {
    return Intl.message(
      'Our company, established in 2024, develops customized systems for factories by integrating advanced technologies such as industrial IoT (Internet of Things), Machine Learning, and Artificial Intelligence. These systems help our customers optimize their production processes, reduce costs, and increase efficiency. Additionally, we further enhance factory operations through our mobile application and web-based solutions.',
      name: 'services_detail',
      desc: '',
      args: [],
    );
  }

  /// `Products`
  String get products {
    return Intl.message(
      'Products',
      name: 'products',
      desc: '',
      args: [],
    );
  }

  /// `Our company offers customized software and hardware products for industrial sectors. Among these are IoT devices and sensors that help factories monitor production processes, analyze data, and make decisions. Additionally, we develop software solutions using machine learning algorithms and artificial intelligence technologies to enhance automation and efficiency in factories.`
  String get products_detail {
    return Intl.message(
      'Our company offers customized software and hardware products for industrial sectors. Among these are IoT devices and sensors that help factories monitor production processes, analyze data, and make decisions. Additionally, we develop software solutions using machine learning algorithms and artificial intelligence technologies to enhance automation and efficiency in factories.',
      name: 'products_detail',
      desc: '',
      args: [],
    );
  }

  /// `About Us`
  String get about_us {
    return Intl.message(
      'About Us',
      name: 'about_us',
      desc: '',
      args: [],
    );
  }

  /// `Established in 2024, our company is a pioneer in industrial transformation, continuously offering innovative solutions to provide our customers with a competitive advantage. With an experienced team and a strong R&D infrastructure, we push the boundaries of industrial IoT, machine learning, and artificial intelligence technologies. Focused on our customers' needs, we aim to deliver scalable, reliable, and user-friendly solutions.`
  String get about_us_detail {
    return Intl.message(
      'Established in 2024, our company is a pioneer in industrial transformation, continuously offering innovative solutions to provide our customers with a competitive advantage. With an experienced team and a strong R&D infrastructure, we push the boundaries of industrial IoT, machine learning, and artificial intelligence technologies. Focused on our customers\' needs, we aim to deliver scalable, reliable, and user-friendly solutions.',
      name: 'about_us_detail',
      desc: '',
      args: [],
    );
  }

  /// `FAQ`
  String get faq {
    return Intl.message(
      'FAQ',
      name: 'faq',
      desc: '',
      args: [],
    );
  }

  /// `Our References`
  String get our_references {
    return Intl.message(
      'Our References',
      name: 'our_references',
      desc: '',
      args: [],
    );
  }

  /// `Our company provides services to numerous clients from various industries. To learn more about our past projects and customer satisfaction, please feel free to contact us. We would be delighted to provide detailed information regarding the references of the companies we have collaborated with.\nFor communication, please reach out to us at sekoyatech@gmail.com or call us at +905077438321. Our expert team will get in touch with you as soon as possible.\n`
  String get our_references_detail {
    return Intl.message(
      'Our company provides services to numerous clients from various industries. To learn more about our past projects and customer satisfaction, please feel free to contact us. We would be delighted to provide detailed information regarding the references of the companies we have collaborated with.\nFor communication, please reach out to us at sekoyatech@gmail.com or call us at +905077438321. Our expert team will get in touch with you as soon as possible.\n',
      name: 'our_references_detail',
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
