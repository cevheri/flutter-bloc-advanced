import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/application/usecases/list_authorities_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mock_classes.dart';

void main() {
  late MockAuthorityRepository repo;
  late ListAuthoritiesUseCase useCase;

  setUp(() {
    repo = MockAuthorityRepository();
    useCase = ListAuthoritiesUseCase(repo);
  });

  test('returns Success when repository returns a non-empty list', () async {
    when(() => repo.list()).thenAnswer((_) async => const Success(['ROLE_USER']));

    final result = await useCase();

    expect(result, isA<Success<List<String>>>());
    expect((result as Success).data, ['ROLE_USER']);
  });

  // Regression coverage for #73: the "empty list = failure" rule now
  // lives in the use case, not AuthorityBloc.
  test('translates Success([]) into a ValidationError Failure', () async {
    when(() => repo.list()).thenAnswer((_) async => const Success([]));

    final result = await useCase();

    expect(result, isA<Failure<List<String>>>());
    final failure = result as Failure<List<String>>;
    expect(failure.error, isA<ValidationError>());
    expect(failure.error.message, 'No authorities found');
  });

  test('propagates a repository Failure unchanged', () async {
    when(() => repo.list()).thenAnswer((_) async => const Failure(ServerError('boom')));

    final result = await useCase();

    expect(result, isA<Failure<List<String>>>());
    expect((result as Failure<List<String>>).error.message, 'boom');
  });
}
