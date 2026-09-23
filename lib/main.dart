import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(MyClassApp(dependencies: AppDependencies.mock(preferences)));
}
