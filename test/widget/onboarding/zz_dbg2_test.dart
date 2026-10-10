import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/onboarding/presentation/onboarding_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
void main() {
  testWidgets('debug shot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    CourseCatalogService.instance.ensureInitialized();
    CourseCatalogService.instance.loadDefaults();
    SubjectController.instance.clearData();
    StudentService.instance.clearProfile();
    AuthIsolation.instance.setAuthenticatedUser('dbg');
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: MediaQuery(data: const MediaQueryData(size: Size(390, 844)), child: RepaintBoundary(child: const OnboardingScreen()))));
    await tester.pumpAndSettle();
    final el = tester.element(find.byType(OnboardingScreen).first);
    RenderRepaintBoundary? rep;
    el.visitAncestorElements((e) { if (e.renderObject is RenderRepaintBoundary) { rep = e.renderObject as RenderRepaintBoundary; return false; } return true; });
    // ignore: avoid_print
    print('REP FOUND: ${rep != null}');
    final image = await rep!.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/tmp/dbg_shot.png').writeAsBytes(bytes!.buffer.asUint8List());
    print('WROTE');
  });
}
