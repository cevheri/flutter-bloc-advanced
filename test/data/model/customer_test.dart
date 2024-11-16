import 'dart:convert';

import 'package:flutter_bloc_advance/data/models/customer.dart';
import 'package:flutter_bloc_advance/main/main_local.mapper.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake/customer_data.dart';

void main() {
  setUp(() {
    initializeJsonMapper();
  });

  group("Customer model", () {
    test("should create a Customer instance (Constructor)", () {
      final finalCustomer = customerMockFullPayload;

      expect(finalCustomer.id, '1');
      expect(finalCustomer.name, 'Acme');
      expect(finalCustomer.phone, '5055055050');
      expect(finalCustomer.cityName, 'Konya');
      expect(finalCustomer.email, 'john.doe@example.com');
      expect(finalCustomer.districtName, "selçuklu");
      expect(finalCustomer.address, 'yazır mh.');
      expect(finalCustomer.active, true);
    });

    test('should copy a Customer instance with new values (copyWith)', () {
      final finalCustomer = customerMockFullPayload;

      final updatedCustomer = finalCustomer.copyWith(
        name: 'new Acme',
        cityName: 'izmir',
        districtName: 'göztepe',
        address: 'yazır',
      );

      expect(updatedCustomer.id, '1');
      expect(updatedCustomer.name, 'new Acme');
      expect(updatedCustomer.phone, '5055055050');
      expect(updatedCustomer.cityName, 'izmir');
      expect(updatedCustomer.email, 'john.doe@example.com');
      expect(updatedCustomer.districtName, 'göztepe');
      expect(updatedCustomer.address, 'yazır');
      expect(updatedCustomer.active, true);
    });

    test('should deserialize from JSON', () {
      final json = customerMockFullPayload.toJson()!;

      final finalCustomer = Customer.fromJson(json);

      expect(finalCustomer?.id, '1');
      expect(finalCustomer?.name, 'Acme');
      expect(finalCustomer?.phone, '5055055050');
      expect(finalCustomer?.cityName, 'Konya');
      expect(finalCustomer?.email, 'john.doe@example.com');
      expect(finalCustomer?.districtName, "selçuklu");
      expect(finalCustomer?.address, 'yazır mh.');
      expect(finalCustomer?.active, true);
    });

    test('should deserialize from JSON string', () {
      final jsonString = jsonEncode(customerMockFullPayload.toJson()!);

      final finalCustomer = Customer.fromJsonString(jsonString);

      expect(finalCustomer?.id, '1');
      expect(finalCustomer?.name, 'Acme');
      expect(finalCustomer?.phone, '5055055050');
      expect(finalCustomer?.cityName, 'Konya');
      expect(finalCustomer?.email, 'john.doe@example.com');
      expect(finalCustomer?.districtName, "selçuklu");
      expect(finalCustomer?.address, 'yazır mh.');
      expect(finalCustomer?.active, true);
    });
  });
}
