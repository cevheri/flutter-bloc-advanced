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
      const entity = mockCustomerFullPayload;

      expect(entity.id, '1');
      expect(entity.name, 'Acme');
      expect(entity.phone, '5055055050');
      expect(entity.cityName, 'Konya');
      expect(entity.email, 'john.doe@example.com');
      expect(entity.districtName, "selçuklu");
      expect(entity.address, 'yazır mh.');
      expect(entity.active, true);
    });

    test('should copy a Customer instance with new values (copyWith)', () {
      const entity = mockCustomerFullPayload;
      final entityUpd = entity.copyWith();

      expect(entityUpd == entity, true);
    });

    test('should copy a Customer instance with new values (copyWith) new values', () {
      const entity = mockCustomerFullPayload;
      final entityUpd = entity.copyWith(name: 'new Acme', cityName: 'izmir', districtName: 'göztepe', address: 'yazır');

      expect(entityUpd.id, '1');
      expect(entityUpd.name, 'new Acme');
      expect(entityUpd.phone, '5055055050');
      expect(entityUpd.cityName, 'izmir');
      expect(entityUpd.email, 'john.doe@example.com');
      expect(entityUpd.districtName, 'göztepe');
      expect(entityUpd.address, 'yazır');
      expect(entityUpd.active, true);
    });

    test('should deserialize from JSON', () {
      final json = mockCustomerFullPayload.toJson()!;
      final entity = Customer.fromJson(json);

      expect(entity?.id, '1');
      expect(entity?.name, 'Acme');
      expect(entity?.phone, '5055055050');
      expect(entity?.cityName, 'Konya');
      expect(entity?.email, 'john.doe@example.com');
      expect(entity?.districtName, "selçuklu");
      expect(entity?.address, 'yazır mh.');
      expect(entity?.active, true);
    });

    test('should deserialize from JSON string', () {
      final jsonString = jsonEncode(mockCustomerFullPayload.toJson()!);
      final entity = Customer.fromJsonString(jsonString);

      expect(entity?.id, '1');
      expect(entity?.name, 'Acme');
      expect(entity?.phone, '5055055050');
      expect(entity?.cityName, 'Konya');
      expect(entity?.email, 'john.doe@example.com');
      expect(entity?.districtName, "selçuklu");
      expect(entity?.address, 'yazır mh.');
      expect(entity?.active, true);
    });

    //props
    test('props test', () {
      const entity = mockCustomerFullPayload;
      final entityUpd = entity.copyWith();

      expect(entity.props, entityUpd.props);
    });

    //toString
    test('should return string', () {
      const entity = mockCustomerFullPayload;

      expect(
        entity.toString(),
        'Customer(1, Acme, 5055055050, john.doe@example.com, Konya, selçuklu, yazır mh., true)',
      );
    });
  });
}
