import 'package:flutter/material.dart' hide Badge;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/dependencies.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final preferences = await SharedPreferences.getInstance();
  final dependencies = AppDependencies.firebase(preferences: preferences);
  await dependencies.notifications.initialize();
  runApp(MyClassApp(dependencies: dependencies));
}
