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

  Future<List<UserEntity>> call(SearchUsersParams params) {
    if ((params.name == null || params.name!.isEmpty) && (params.authorities == null || params.authorities!.isEmpty)) {
      return _repository.list(page: params.page, size: params.size);
    }

    if (params.name != null &&
        params.name!.isNotEmpty &&
        params.authorities != null &&
        params.authorities!.isNotEmpty) {
      return _repository.listByNameAndRole(params.page, params.size, params.name!, params.authorities!);
    }

    return _repository.listByAuthority(params.page, params.size, params.authorities!);
  }
}
