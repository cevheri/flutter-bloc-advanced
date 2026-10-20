import 'package:flutter_bloc_advance/core/result/result.dart';

abstract class IAuthorityRepository {
  Future<Result<List<String>>> list();
}
