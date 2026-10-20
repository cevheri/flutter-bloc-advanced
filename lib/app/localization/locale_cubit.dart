import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/core/logging/app_logger.dart';
import 'package:flutter_bloc_advance/generated/l10n.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';

part 'locale_state.dart';

/// Owns the language the app shows. `App` builds its `MaterialApp` with [LocaleState.locale].
///
/// The language the user picked is stored on the device under [StorageKeys.language], a device preference that is
/// not part of the session. Without a stored language the app shows the configured default.
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({required this._storage, required Locale defaultLocale}) : super(LocaleRestoring(locale: defaultLocale));

  static final _log = AppLogger.getLogger('LocaleCubit');

  final AppLocalStorage _storage;

  /// Reads the stored language, so the app starts in the language the user picked. The configured default stays when
  /// no language is stored. It also stays, with an error in the log, when the stored value is not a language the app
  /// supports or cannot be read.
  Future<void> restore() async {
    final defaultLocale = state.locale;
    final Object? stored;
    try {
      stored = await _storage.read(StorageKeys.language.key);
    } catch (error, stackTrace) {
      _log.error('restore: could not read the stored language, showing {}: {}', [defaultLocale, error]);
      addError(error, stackTrace);
      emit(LocaleReady(locale: defaultLocale));
      return;
    }
    if (stored == null) {
      _log.debug('restore: no stored language, showing {}', [defaultLocale]);
      emit(LocaleReady(locale: defaultLocale));
      return;
    }
    if (stored is! String || !S.delegate.isSupported(Locale(stored))) {
      _log.error('restore: the stored language {} is not supported, showing {}', [stored, defaultLocale]);
      emit(LocaleReady(locale: defaultLocale));
      return;
    }
    _log.debug('restore: showing the stored language {}', [stored]);
    emit(LocaleReady(locale: Locale(stored)));
  }
}
