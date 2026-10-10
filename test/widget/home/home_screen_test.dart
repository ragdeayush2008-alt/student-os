import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  Widget buildTestableHomeScreen({double width = 390.0, double height = 844.0}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: const HomeScreen(),
      ),
    );
  }

  group('Home 2.0 Widget Tests (A, B, C, D, E, F, Y, Z)', () {
    testWidgets('B. Home renders gracefully with empty data without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Add Task'), findsWidgets);
      expect(find.text('Study'), findsWidgets);
      expect(find.text('Focus'), findsWidgets);
      expect(find.text('Exams'), findsWidgets);
      expect(find.text('Plan Day'), findsWidgets);
      expect(find.text('Revise'), findsWidgets);
      expect(find.text('Ask Student OS'), findsWidgets);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Y & Z. Home builds without RenderFlex overflow on narrow width (320dp)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      await tester.pumpWidget(buildTestableHomeScreen(width: 320, height: 600));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Y & Z. Home builds without RenderFlex overflow on standard width (360dp)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(buildTestableHomeScreen(width: 360, height: 800));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('F. Active Focus displays Continue Focus card on Home', (tester) async {
      FocusController.instance.startQuickFocus(subjectName: 'Economics');
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('FOCUS ACTIVE'), findsOneWidget);
      expect(find.text('Continue Focus'), findsOneWidget);

      FocusController.instance.cancelSession();
    });
  });
}
