part of 'theme_bloc.dart';

class ThemeState {
  const ThemeState({this.palette = AppThemePalette.classic, this.isDarkMode = false});

  final AppThemePalette palette;
  final bool isDarkMode;

  ThemeState copyWith({AppThemePalette? palette, bool? isDarkMode}) {
    return ThemeState(palette: palette ?? this.palette, isDarkMode: isDarkMode ?? this.isDarkMode);
  }
}
