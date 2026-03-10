import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_bloc_advance/shared/design_system/theme/app_theme_palette.dart';

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
      final brightnessPref = await AppLocalStorage().read(StorageKeys.brightness.name);
      final isDarkMode = brightnessPref == 'dark';

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
    } catch (_) {
      emit(state.copyWith(palette: AppThemePalette.classic, isDarkMode: false));
    }
  }

  Future<void> _onChangeThemePalette(ChangeThemePalette event, Emitter<ThemeState> emit) async {
    emit(state.copyWith(palette: event.palette));
    try {
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
    } catch (_) {}
  }

  Future<void> _onToggleBrightness(ToggleBrightness event, Emitter<ThemeState> emit) async {
    final newIsDarkMode = !state.isDarkMode;
    emit(state.copyWith(isDarkMode: newIsDarkMode));
    try {
      await AppLocalStorage().save(StorageKeys.brightness.name, newIsDarkMode ? 'dark' : 'light');
    } catch (_) {}
  }
}
