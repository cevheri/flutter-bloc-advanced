import 'package:flutter/material.dart';

/// This class contains all the themes used in the application.
///
/// The themes are based on the Light and Dark themes from the Material Design specification.
class Themes {

  static final MaterialColor primaryColorLight =  Colors.indigo;
  static final MaterialColor secondaryColorLight =  Colors.pink;
  static final MaterialAccentColor primaryColorAccentLight =  Colors.indigoAccent;
  static final MaterialAccentColor secondaryColorAccentLight =  Colors.pinkAccent;

  static final double header1FontSize =  30.0;
  static final double header3FontSize =  25.0;
  static final double baseFontSize =  15.0;

  static final String fontFamilyLight =  'Roboto';
  static final String fontFamilyDark =  'Roboto';

  /// Light theme based on the Material Design Light theme.
  ///
  /// See https://material.io/design/color/the-color-system.html#color-theme-creation
  static final ThemeData light = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    fontFamily: fontFamilyLight,
    primaryColor: primaryColorLight,
    errorColor: Colors.red,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      errorStyle: TextStyle(color: Colors.red),
    ),
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColorLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      secondary: secondaryColorLight,
      error: Colors.red,
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      elevation: 4,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColorLight,
      textTheme: ButtonTextTheme.primary,
      colorScheme: ColorScheme.light(primary: primaryColorLight),
      height: 50,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    textTheme: TextTheme(
      headline1: TextStyle(
          color: Colors.black, fontSize: header1FontSize, fontWeight: FontWeight.bold),
      headline2: TextStyle(
          color: Colors.white, fontSize: header1FontSize, fontWeight: FontWeight.bold),
      headline3: TextStyle(
          color: Colors.black, fontSize: header3FontSize, fontWeight: FontWeight.bold),
      headline4: TextStyle(
          color: Colors.white, fontSize: header3FontSize, fontWeight: FontWeight.bold),
      bodyText1: TextStyle(color: Colors.black, fontSize: baseFontSize),
      bodyText2: TextStyle(color: Colors.white, fontSize: baseFontSize),
    ),
  );


  /// Dark theme based on the Material Design Dark theme.
  ///
  /// See https://material.io/design/color/the-color-system.html#color-theme-creation
  static final ThemeData dark = ThemeData(
    scaffoldBackgroundColor: Colors.black,
  );
}