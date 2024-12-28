import 'package:flutter_bloc_advance/presentation/screen/home/home_screen.dart';
import 'package:flutter_bloc_advance/routes/app_routes_constants.dart';
import 'package:go_router/go_router.dart';

class HomeRoutes {
  static final List<GoRoute> routes = [
    GoRoute(name: 'home', path: ApplicationRoutesConstants.home, builder: (context, state) => HomeScreen()),
  ];
}
