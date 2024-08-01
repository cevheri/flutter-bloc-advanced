import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/sales_person.dart';

class SalesPersonRepository {
  SalesPersonRepository();

  Future<List<SalesPerson>> getSalesPerson() async {
    final result = await HttpUtils.get("/sales-people");
    return JsonMapper.deserialize<List<SalesPerson>>(result)!;
  }
}