import 'package:flutter_bloc_advance/features/settings/application/usecases/change_language_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ChangeLanguageUseCase useCase;

  setUp(() {
    useCase = const ChangeLanguageUseCase();
  });

  test('returns the language when valid', () {
    expect(useCase.call('en'), 'en');
    expect(useCase.call('tr'), 'tr');
  });

  test('throws ArgumentError when language is null', () {
    expect(() => useCase.call(null), throwsA(isA<ArgumentError>()));
  });

  test('throws ArgumentError when language is empty', () {
    expect(() => useCase.call(''), throwsA(isA<ArgumentError>()));
  });
}
