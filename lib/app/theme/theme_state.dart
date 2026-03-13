part of 'theme_bloc.dart';

class ThemeState {
  const ThemeState({this.palette = AppThemePalette.classic, this.themeMode = ThemeMode.system});

  final AppThemePalette palette;
  final ThemeMode themeMode;

  ThemeState copyWith({AppThemePalette? palette, ThemeMode? themeMode}) {
    return ThemeState(palette: palette ?? this.palette, themeMode: themeMode ?? this.themeMode);
  }
}
