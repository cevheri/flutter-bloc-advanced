import 'package:flutter/services.dart';

import '../models/dashboard_model.dart';

/// Abstraction for dashboard data source
abstract class DashboardRepository {
  Future<DashboardModel> fetch();
}

/// Mock implementation that reads JSON from assets for local/dev runs
class DashboardMockRepository implements DashboardRepository {
  @override
  Future<DashboardModel> fetch() async {
    final json = await rootBundle.loadString('assets/mock/dashboard.json');
    return DashboardModel.fromJsonString(json);
  }
}
