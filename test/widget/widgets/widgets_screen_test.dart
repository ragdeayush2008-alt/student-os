import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/premium/services/entitlement_service.dart';
import 'package:student_os/features/widgets/presentation/widgets_screen.dart';

/// Widgets catalog screen: all families listed, honest PRO/SOON markers,
/// responsive layouts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
  });

  tearDown(() async {
    AuthIsolation.instance.clearSession();
    EntitlementService.instance.clearData();
  });

  Widget wrap({double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: const Scaffold(body: WidgetsScreen()),
      ),
    );
  }

  testWidgets('lists essentials with honest markers', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Essentials'), findsOneWidget);
    expect(find.text('Next Exam Countdown'), findsOneWidget);
    expect(find.text('Quick Focus'), findsOneWidget);
    expect(find.text('Sleep'), findsWidgets);
    // Debug tools visible in test (debug) builds only.
    expect(find.text('Developer tools'), findsOneWidget);
  });

  testWidgets('no overflow at 360dp and 390dp', (tester) async {
    for (final width in [360.0, 390.0]) {
      await tester.pumpWidget(wrap(width: width));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
