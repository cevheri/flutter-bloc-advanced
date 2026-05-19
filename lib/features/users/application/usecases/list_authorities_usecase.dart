import 'package:flutter_bloc_advance/core/errors/app_error.dart';
import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/authority_repository.dart';

/// Loads the authority catalog. Returns a [ValidationError] failure
/// when the catalog is empty — an unusable authority dropdown should
/// surface as an error to the UI rather than silently rendering empty.
class ListAuthoritiesUseCase {
  const ListAuthoritiesUseCase(this._repository);

  final IAuthorityRepository _repository;

  Future<Result<List<String>>> call() async {
    final result = await _repository.list();
    return switch (result) {
      Success(:final data) when data.isEmpty => const Failure(
        ValidationError('No authorities found', code: 'user.no_authorities'),
      ),
      _ => result,
    };
  }
}
