import 'package:flutter/material.dart';

/// This class contains all the themes used in the application.
///
/// The themes are based on the Light and Dark themes from the Material Design specification.
class Themes {
  static final MaterialColor primaryColorLight = Colors.indigo;
  static final MaterialColor secondaryColorLight = Colors.pink;

  static final MaterialColor primaryColorDark = Colors.indigo;
  static final MaterialColor secondaryColorDark = Colors.pink;

  static final MaterialAccentColor primaryColorAccentLight = Colors.indigoAccent;
  static final MaterialAccentColor secondaryColorAccentLight = Colors.pinkAccent;

  static final double header1FontSize = 30.0;
  static final double header3FontSize = 25.0;
  static final double baseFontSize = 15.0;

  static final String fontFamilyLight = 'Roboto';
  static final String fontFamilyDark = 'Roboto';

  static ColorScheme colorSchemeDark() {
    return ColorScheme(
      error: Colors.red,
      brightness: Brightness.dark,
      primary: primaryColorDark,
      onPrimary: Colors.white,
      secondary: secondaryColorDark,
      onSecondary: Colors.white,
      onError: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      surface: Colors.black,
      onSurface: Colors.white,
    );
  }

  static ColorScheme colorSchemeLight() {
    return ColorScheme(
      error: Colors.red,
      brightness: Brightness.light,
      primary: primaryColorLight,
      onPrimary: Colors.white,
      secondary: secondaryColorLight,
      onSecondary: Colors.white,
      onError: Colors.white,
      background: Colors.white,
      onBackground: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black,
    );
  }

  /// Light theme based on the Material Design Light theme.
  ///
  /// See https://material.io/design/color/the-color-system.html#color-theme-creation
  static final ThemeData light = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    fontFamily: fontFamilyLight,
    primaryColor: primaryColorLight,
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
      displayLarge: TextStyle(color: Colors.black, fontSize: header1FontSize, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontSize: header1FontSize, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.black, fontSize: header3FontSize, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontSize: header3FontSize, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black, fontSize: baseFontSize),
      bodyMedium: TextStyle(color: Colors.white, fontSize: baseFontSize),
    ),
  );

  /// Dark theme based on the Material Design Dark theme.
  ///
  /// See https://material.io/design/color/the-color-system.html#color-theme-creation
  static final ThemeData dark = ThemeData(
    scaffoldBackgroundColor: Colors.black,
    fontFamily: fontFamilyDark,
    primaryColor: primaryColorDark,

    // dark mode for inputDecoration
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      errorStyle: TextStyle(color: Colors.red),
    ),

    // dark mode for appBar
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),

    // dark mode for colorScheme
    colorScheme: ColorScheme.dark(
      primary: primaryColorDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      secondary: secondaryColorDark,
      error: Colors.red,
    ),

    // dark mode for cardTheme
    cardTheme: const CardTheme(
      color: Colors.black,
      elevation: 4,
    ),

    // dark mode for buttonTheme
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColorDark,
      textTheme: ButtonTextTheme.primary,
      colorScheme: ColorScheme.dark(primary: primaryColorDark),
      height: 50,
    ),

    // dark mode for iconTheme
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),

    // dark mode for textTheme
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.black, fontSize: header1FontSize, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontSize: header1FontSize, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.black, fontSize: header3FontSize, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontSize: header3FontSize, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black, fontSize: baseFontSize),
      bodyMedium: TextStyle(color: Colors.white, fontSize: baseFontSize),
    ),
  );
}
