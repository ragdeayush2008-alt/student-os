// TEMPORARY visual-inspection harness (deleted before final verification).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/features/onboarding/presentation/onboarding_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setup() async {
    SharedPreferences.setMockInitialValues({});
    CourseCatalogService.instance.ensureInitialized();
    CourseCatalogService.instance.loadDefaults();
    SubjectController.instance.clearData();
    StudentService.instance.clearProfile();
    AuthIsolation.instance.setAuthenticatedUser('shot_user');
  }

  Future<void> pump(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Shot');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('capture step2 states', (tester) async {
    await setup();
    await pump(tester);
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/zz_step2_home.png'),
    );
  });
}
