import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/local_storage.dart';
import 'package:flutter_bloc_advance/presentation/design_system/theme/app_theme_palette.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeThemePalette>(_onChangeThemePalette);
    on<ToggleBrightness>(_onToggleBrightness);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      // Load brightness preference from storage
      final brightnessPref = await AppLocalStorage().read(StorageKeys.brightness.name);
      final isDarkMode = brightnessPref == 'dark';

      // Load palette preference from storage
      final palettePref = await AppLocalStorage().read(StorageKeys.theme.name);
      AppThemePalette palette = AppThemePalette.classic;

      if (palettePref != null) {
        switch (palettePref) {
          case 'classic':
            palette = AppThemePalette.classic;
            break;
          case 'nature':
            palette = AppThemePalette.nature;
            break;
          case 'sunset':
            palette = AppThemePalette.sunset;
            break;
          default:
            palette = AppThemePalette.classic;
        }
      }

      emit(state.copyWith(palette: palette, isDarkMode: isDarkMode));
    } catch (e) {
      // Default to classic palette and light mode if loading fails
      emit(state.copyWith(palette: AppThemePalette.classic, isDarkMode: false));
    }
  }

  Future<void> _onChangeThemePalette(ChangeThemePalette event, Emitter<ThemeState> emit) async {
    try {
      // Save palette preference to storage
      String paletteName;
      switch (event.palette) {
        case AppThemePalette.classic:
          paletteName = 'classic';
          break;
        case AppThemePalette.nature:
          paletteName = 'nature';
          break;
        case AppThemePalette.sunset:
          paletteName = 'sunset';
          break;
      }
      await AppLocalStorage().save(StorageKeys.theme.name, paletteName);
      emit(state.copyWith(palette: event.palette));
    } catch (e) {
      // Still update the state even if saving fails
      emit(state.copyWith(palette: event.palette));
    }
  }

  Future<void> _onToggleBrightness(ToggleBrightness event, Emitter<ThemeState> emit) async {
    debugPrint("ThemeBloc: _onToggleBrightness called. Current isDarkMode: ${state.isDarkMode}");
    try {
      final newIsDarkMode = !state.isDarkMode;
      debugPrint("ThemeBloc: Setting new isDarkMode to: $newIsDarkMode");
      // Save brightness preference to storage
      await AppLocalStorage().save(StorageKeys.brightness.name, newIsDarkMode ? 'dark' : 'light');
      emit(state.copyWith(isDarkMode: newIsDarkMode));
      debugPrint("ThemeBloc: State updated successfully");
    } catch (e) {
      debugPrint("ThemeBloc: Error in _onToggleBrightness: $e");
      // Still update the state even if saving fails
      emit(state.copyWith(isDarkMode: !state.isDarkMode));
    }
  }
}
