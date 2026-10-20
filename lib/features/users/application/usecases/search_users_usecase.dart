import 'package:flutter_bloc_advance/core/result/result.dart';
import 'package:flutter_bloc_advance/features/users/domain/repositories/user_repository.dart';
import 'package:flutter_bloc_advance/shared/models/user_entity.dart';

class SearchUsersParams {
  const SearchUsersParams({this.page = 0, this.size = 10, this.authorities, this.name});

  final int page;
  final int size;
  final String? authorities;
  final String? name;
}

class SearchUsersUseCase {
  const SearchUsersUseCase(this._repository);

  final IUserRepository _repository;

  /// Picks the repository search for the filters given; an empty name or role counts as not given.
  Future<Result<List<UserEntity>>> call(SearchUsersParams params) {
    return switch ((_nonEmpty(params.name), _nonEmpty(params.authorities))) {
      (null, null) => _repository.list(page: params.page, size: params.size),
      (final String name, null) => _repository.listByName(params.page, params.size, name),
      (null, final String authority) => _repository.listByAuthority(params.page, params.size, authority),
      (final String name, final String authority) => _repository.listByNameAndRole(
        params.page,
        params.size,
        name,
        authority,
      ),
    };
  }

  static String? _nonEmpty(String? value) => value == null || value.isEmpty ? null : value;
}
