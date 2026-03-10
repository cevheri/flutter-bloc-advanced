import 'package:flutter/material.dart';
import 'package:flutter_bloc_advance/app/app.dart' as modern_app;
import 'package:flutter_bloc_advance/app/di/app_dependencies.dart';

class App extends modern_app.App {
  const App({
    super.key,
    required super.language,
    super.dependencies = const AppDependencies(),
  });

  Widget buildHomeApp() => this;
}
