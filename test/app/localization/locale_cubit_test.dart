import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_advance/app/localization/locale_cubit.dart';
import 'package:flutter_bloc_advance/infrastructure/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level, Logger, OutputEvent;
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage whose reads fail, like a device whose preferences cannot be loaded.
class _UnreadableStorage implements AppLocalStorage {
  @override
  Future<dynamic> read(String key) async => throw StateError('boom on read $key');
  @override
  Future<bool> save(String key, dynamic value) => AppLocalStorage().save(key, value);
  @override
  Future<bool> remove(String key) => AppLocalStorage().remove(key);
  @override
  Future<void> clear() => AppLocalStorage().clear();
  @override
  void setPreferencesInstance(SharedPreferences prefs) => AppLocalStorage().setPreferencesInstance(prefs);
}

/// Collects the lines logged at error level until the test ends.
List<String> _recordErrorLogs() {
  final errors = <String>[];
  void record(OutputEvent event) {
    if (event.level == Level.error) errors.addAll(event.lines);
  }

  Logger.addOutputListener(record);
  addTearDown(() => Logger.removeOutputListener(record));
  return errors;
}

void main() {
  group('LocaleCubit', () {
    test('starts in the configured default while it restores', () {
      final cubit = LocaleCubit(storage: AppLocalStorage(), defaultLocale: const Locale('tr'));
      addTearDown(cubit.close);

      expect(cubit.state, const LocaleRestoring(locale: Locale('tr')));
    });

    group('restore', () {
      blocTest<LocaleCubit, LocaleState>(
        'shows the stored language',
        setUp: () => AppLocalStorage().save(StorageKeys.language.key, 'tr'),
        build: () => LocaleCubit(storage: AppLocalStorage(), defaultLocale: const Locale('en')),
        act: (cubit) => cubit.restore(),
        expect: () => const [LocaleReady(locale: Locale('tr'))],
      );

      blocTest<LocaleCubit, LocaleState>(
        'shows the configured default when no language is stored',
        build: () => LocaleCubit(storage: AppLocalStorage(), defaultLocale: const Locale('tr')),
        act: (cubit) => cubit.restore(),
        expect: () => const [LocaleReady(locale: Locale('tr'))],
      );

      test('shows the configured default and logs an error when the stored language is not supported', () async {
        await AppLocalStorage().save(StorageKeys.language.key, 'de');
        final errors = _recordErrorLogs();
        final cubit = LocaleCubit(storage: AppLocalStorage(), defaultLocale: const Locale('tr'));
        addTearDown(cubit.close);

        await cubit.restore();

        expect(cubit.state, const LocaleReady(locale: Locale('tr')));
        expect(errors, contains(allOf(contains('LocaleCubit'), contains('de'))));
      });

      blocTest<LocaleCubit, LocaleState>(
        'shows the configured default and reports the error when the stored language cannot be read',
        build: () => LocaleCubit(storage: _UnreadableStorage(), defaultLocale: const Locale('tr')),
        act: (cubit) => cubit.restore(),
        expect: () => const [LocaleReady(locale: Locale('tr'))],
        errors: () => [isA<StateError>()],
      );
    });
  });
}
