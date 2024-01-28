
import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/status.dart';
import '../models/status_next.dart';

class StatusRepository {
  StatusRepository();

  Future<List<Status>> listStatus() async {
      final request = await HttpUtils.get("/offering-statuses");
      var result = JsonMapper.deserialize<List<Status>>(request)!;
      List<Status> activeStatus = result.where((element) => element.active == true).toList();
      activeStatus.sort((a, b) => a.orderPriority!.compareTo(b.orderPriority!));
      return activeStatus;
  }

  Future<List<Status>> listStatusWithOffer(String offerStatusId, String authority) async {
      final request = await HttpUtils.get("/offering-statuses?authorityName.equals=$authority&parentId.equals=$offerStatusId&page=0&size=20");
      var result = JsonMapper.deserialize<List<Status>>(request)!;
      return result;
  }
}


