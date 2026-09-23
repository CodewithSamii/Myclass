import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myclass/app.dart';
import 'package:myclass/core/dependencies.dart';
import 'package:myclass/core/models.dart';
import 'package:myclass/shared/workspace_shell.dart';

UserProfile sampleProfile({
  UserRole role = UserRole.student,
  Appearance appearance = Appearance.light,
}) => UserProfile(
  uid: 'demo-student',
  name: 'Navid',
  email: 'student@example.edu',
  memberships: [
    SectionMembership(
      sectionId: 'bsc-cse-64-I',
      departmentId: 'cse',
      programId: 'bsc-cse',
      batchId: 'bsc-cse-64',
      programName: 'B.Sc. in Computer Science & Engineering',
      batchName: 'Batch 64',
      sectionName: 'Section I',
      role: role,
    ),
  ],
  activeSectionId: 'bsc-cse-64-I',
  appearance: appearance,
);
Future<void> loadFonts() async {
  for (final entry in {
    'Inter': 'assets/fonts/Inter.ttf',
    'packages/cupertino_icons/CupertinoIcons':
        'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
  }.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<AppDependencies> boot(
  WidgetTester tester, {
  UserRole role = UserRole.student,
  Appearance appearance = Appearance.light,
  bool signedIn = true,
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  SharedPreferences.setMockInitialValues(
    signedIn
        ? {
            'myclass.signedIn': true,
            'myclass.profile.demo-student': jsonEncode(
              sampleProfile(role: role, appearance: appearance).toJson(),
            ),
          }
        : {},
  );
  final preferences = await SharedPreferences.getInstance();
  final d = AppDependencies.mock(preferences);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('capture'),
      child: MyClassApp(dependencies: d),
    ),
  );
  await settle(tester);
  return d;
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/screenshots/$name.png');
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
  expect(
    tester.takeException(),
    isNull,
    reason: 'No rendering errors on $name',
  );
}

Future<void> push(WidgetTester tester, Widget page) async {
  final context = tester.element(find.byType(WorkspaceShell));
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  await settle(tester);
}

Future<void> back(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester);
}

Future<void> finish(WidgetTester tester, AppDependencies d) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  d.dispose();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}
