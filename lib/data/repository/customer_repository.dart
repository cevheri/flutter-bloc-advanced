import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/customer.dart';

/// customer repository
///
/// This class is responsible for all the customer related operations
/// list, create, update, delete etc.
class CustomerRepository {
  /// Retrieve all customers method that retrieves all the customers
  Future<List<Customer>> getCustomers() async {
    final customersRequest = await HttpUtils.getRequest("/customers");
    return JsonMapper.deserialize<List<Customer>>(customersRequest)!;
  }

  /// Retrieve customer method that retrieves a customer by id
  ///
  /// @param id the customer id
  Future<Customer> getCustomer(String id) async {
    final customerRequest = await HttpUtils.getRequest("/customers/$id");
    return JsonMapper.deserialize<Customer>(customerRequest)!;
  }



  /// Find customer method that findCustomer a customer
  Future<List<Customer>> listCustomer(
    int rangeStart,
    int rangeEnd,
  ) async {

    final getRequest = await HttpUtils.getRequest(
        "/customers?page=${rangeStart.toString()}&size=${rangeEnd.toString()}");
    return JsonMapper.deserialize<List<Customer>>(getRequest)!;
  }

  /// Find customer method that findCustomerByName a customer
  Future<List<Customer>> findCustomerByName(
    String name,
  ) async {
    final customerRequest = await HttpUtils.getRequest(
        "/customers?name.contains=$name&page=0&size=100");
    var result = JsonMapper.deserialize<List<Customer>>(customerRequest)!;
    return result;
  }
}
