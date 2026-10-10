import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/focus/controller/focus_guard_controller.dart';
import 'package:student_os/features/focus/presentation/screens/focus_session_screen.dart';
import 'package:student_os/features/focus/services/focus_guard_service.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ragdetechnologies.student_os/focus_guard');

  bool usageAccess = true;
  bool overlayPermission = true;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.clearUser(userId: 'demo');
    AuthIsolation.instance.setAuthenticatedUser('demo');
    FocusController.instance.clearData();
    FocusGuardController.instance.clearData();
    SubjectController.instance.clearData();
    usageAccess = true;
    overlayPermission = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'isSupported':
          return true;
        case 'hasUsageAccess':
          return usageAccess;
        case 'hasOverlayPermission':
          return overlayPermission;
        default:
          return null;
      }
    });

    FocusGuardService.instance = FocusGuardService(isAndroidOverride: true);
    FocusGuardController.instance =
        FocusGuardController(service: FocusGuardService.instance);
    await FocusGuardController.instance.load();
    await FocusGuardController.instance.refreshPermissions();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    FocusGuardController.instance.clearData();
    FocusController.instance.clearData();
    SubjectController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      routes: AppRouter.routes(),
      home: child,
    );
  }

  Future<void> pumpFocus(WidgetTester tester) async {
    FocusController.instance.startFocusGuard(
      duration: const Duration(minutes: 25),
      subjectName: 'Accounting',
    );
    await tester.pumpWidget(wrapWithApp(const FocusSessionScreen()));
    await tester.pumpAndSettle();
  }

  group('SprintX Guard card states (Focus entry point)', () {
    testWidgets('Setup Needed when a permission is missing', (tester) async {
      usageAccess = false;
      await FocusGuardController.instance.refreshPermissions();
      await pumpFocus(tester);

      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text('Setup Needed'), findsOneWidget);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Ready when configured but paused', (tester) async {
      await FocusGuardController.instance.setGuardEnabled(false);
      await pumpFocus(tester);

      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Setup Needed'), findsNothing);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Active with blocked apps configured', (tester) async {
      await FocusGuardController.instance.setBlockedPackages({
        'com.example.game',
        'com.example.social',
      });
      await pumpFocus(tester);

      expect(find.text('Focus Guard'), findsOneWidget);
      expect(find.text('2 app(s)'), findsOneWidget);
      expect(find.text('Setup Needed'), findsNothing);
      expect(tester.takeException(), isNull);

      FocusController.instance.clearData();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
