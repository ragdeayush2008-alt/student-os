import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/data/models/catalog/course_category.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Course Selection & Onboarding Persistence on Reopen Regression', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      CourseCatalogService.instance.ensureInitialized();
      CourseCatalogService.instance.loadDefaults();
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.setAuthenticatedUser('user_ca_foundation');
    });

    tearDown(() {
      SubjectController.instance.clearData();
      StudentService.instance.clearProfile();
      AuthIsolation.instance.clearSession();
    });

    test('1. First-time user requires onboarding', () async {
      final service = StudentService.instance;
      expect(service.profile.isOnboardingComplete, isFalse);
      expect(service.isOnboardingComplete, isFalse);
    });

    test('2. After course selection and completeOnboarding, profile is complete & persisted', () async {
      final service = StudentService.instance;

      await service.updateDisplayName('CA Student');
      await service.updateCatalogEducation(
        category: CourseCategory.professional,
        courseId: 'ca_foundation',
        courseName: 'CA Foundation',
      );
      await service.completeOnboarding();

      expect(service.profile.isOnboardingComplete, isTrue);
      expect(service.profile.displayName, 'CA Student');
      expect(service.profile.course, 'CA Foundation');
    });

    test('3. Simulated app reopen restores completed onboarding without reverting to course selection', () async {
      final service = StudentService.instance;

      // 1. User completes onboarding
      await service.updateDisplayName('CA Student');
      await service.updateCatalogEducation(
        category: CourseCategory.professional,
        courseId: 'ca_foundation',
        courseName: 'CA Foundation',
      );
      await service.completeOnboarding();
      expect(service.profile.isOnboardingComplete, isTrue);

      // 2. Simulate app close (memory cleared, persistent SharedPreferences intact)
      service.clearProfile();
      expect(service.isLoaded, isFalse);
      expect(service.profile.isOnboardingComplete, isFalse);

      // 3. Simulate app reopen startup sequence: Auth restoration -> load() -> initializeFromAuth()
      await service.load();
      await service.initializeFromAuth();

      // Must remain complete!
      expect(service.isLoaded, isTrue);
      expect(service.profile.isOnboardingComplete, isTrue);
      expect(service.profile.displayName, 'CA Student');
      expect(service.profile.course, 'CA Foundation');
    });

    test('4. Logout clears memory and Login again restores user course without prompting onboarding', () async {
      final service = StudentService.instance;

      // User A setup
      AuthIsolation.instance.setAuthenticatedUser('user_a');
      await service.updateDisplayName('User A');
      await service.updateCatalogEducation(
        category: CourseCategory.professional,
        courseId: 'ca_foundation',
        courseName: 'CA Foundation',
      );
      await service.completeOnboarding();
      expect(service.profile.isOnboardingComplete, isTrue);

      // User logs out: clear controllers & memory
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();
      expect(service.profile.isOnboardingComplete, isFalse);

      // User logs back in
      AuthIsolation.instance.setAuthenticatedUser('user_a');
      await service.load();
      await service.initializeFromAuth();

      expect(service.profile.isOnboardingComplete, isTrue);
      expect(service.profile.displayName, 'User A');
      expect(service.profile.course, 'CA Foundation');
    });

    test('5. Multi-user isolation: User A (CA Foundation) vs User B (B.Tech) do not leak', () async {
      final service = StudentService.instance;

      // User A (CA Foundation)
      AuthIsolation.instance.setAuthenticatedUser('user_ca');
      await service.updateDisplayName('CA Student');
      await service.updateCatalogEducation(
        category: CourseCategory.professional,
        courseId: 'ca_foundation',
        courseName: 'CA Foundation',
      );
      await service.completeOnboarding();

      // Switch to User B (B.Tech)
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();
      AuthIsolation.instance.setAuthenticatedUser('user_btech');
      service.clearProfile();

      await service.load();
      // User B has not onboarded yet
      expect(service.profile.isOnboardingComplete, isFalse);
      expect(service.profile.course, isEmpty);

      // User B onboards
      await service.updateDisplayName('Engineer');
      await service.updateCatalogEducation(
        category: CourseCategory.undergraduate,
        courseId: 'btech_cs',
        courseName: 'B.Tech Computer Science',
      );
      await service.completeOnboarding();

      expect(service.profile.isOnboardingComplete, isTrue);
      expect(service.profile.course, 'B.Tech Computer Science');

      // Switch back to User A
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();
      AuthIsolation.instance.setAuthenticatedUser('user_ca');
      service.clearProfile();

      await service.load();
      await service.initializeFromAuth();

      expect(service.profile.isOnboardingComplete, isTrue);
      expect(service.profile.displayName, 'CA Student');
      expect(service.profile.course, 'CA Foundation');
    });
  });
}
