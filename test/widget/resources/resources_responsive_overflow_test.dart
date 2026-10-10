import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/resources/resources_screen.dart';
import 'package:student_os/features/subjects/subject_controller.dart';

Widget _buildTestApp(Widget child, {Size size = const Size(390, 844)}) {
  return MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.dark,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: AppScope(
        controller: AppShellController(),
        child: AuthScope(
          authService: AuthService.instance,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_knowledge_user');
    SubjectController.instance.clearData();
    ExamController.instance.clearData();
    ResourceController.instance.clearData();
    await SubjectController.instance.load();
    await ExamController.instance.load();
    await ResourceController.instance.load();
  });

  tearDown(() {
    SubjectController.instance.clearData();
    ExamController.instance.clearData();
    ResourceController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Knowledge (ResourcesScreen) Responsive & Overflow Tests', () {
    testWidgets('renders cleanly without overflow with 0 subjects and 0 resources', (tester) async {
      await tester.pumpWidget(_buildTestApp(const ResourcesScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your knowledge'), findsOneWidget);
      expect(find.text('Build your academic library'), findsOneWidget);
      expect(find.text('New note'), findsOneWidget);
      expect(find.text('Add link'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow with 4 subjects and long names', (tester) async {
      final sub1 = await SubjectController.instance.createSubject(
        name: 'Audit & Assurance & Corporate Governance',
      );
      final sub2 = await SubjectController.instance.createSubject(
        name: 'Business Law & Business Correspondence',
      );
      final sub3 = await SubjectController.instance.createSubject(
        name: 'Fundamentals of Financial & Cost Accounting',
      );
      final sub4 = await SubjectController.instance.createSubject(
        name: 'Taxation & Economic Regulatory Law',
      );

      // Add resources for subjects
      await ResourceController.instance.createResource(
        title: 'Complete Audit Framework Summary Notes',
        resourceType: ResourceType.note,
        subjectId: sub1.id,
      );
      await ResourceController.instance.createResource(
        title: 'Business Law Case Digest Reference',
        resourceType: ResourceType.link,
        reference: 'https://example.com/law',
        subjectId: sub2.id,
      );
      await ResourceController.instance.createResource(
        title: 'Accounting Practice Sets & Worksheets',
        resourceType: ResourceType.document,
        subjectId: sub3.id,
      );
      await ResourceController.instance.createResource(
        title: 'Direct and Indirect Tax Rates Master Table',
        resourceType: ResourceType.revision,
        subjectId: sub4.id,
        isFavorite: true,
      );

      await tester.pumpWidget(_buildTestApp(const ResourcesScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your knowledge'), findsOneWidget);
      expect(find.text('Your subjects'), findsOneWidget);
      expect(find.text('Audit & Assurance & Corporate Governance'), findsWidgets);
      expect(find.text('Business Law & Business Correspondence'), findsWidgets);
    });

    testWidgets('renders cleanly with 1 subject and many resources', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Economics');

      for (int i = 1; i <= 15; i++) {
        await ResourceController.instance.createResource(
          title: 'Economics Chapter $i Comprehensive Notes and Formula Sheet',
          resourceType: i % 2 == 0 ? ResourceType.note : ResourceType.link,
          subjectId: sub.id,
          tags: ['chapter$i', 'macroeconomics', 'exam-prep'],
        );
      }

      await tester.pumpWidget(_buildTestApp(const ResourcesScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your knowledge'), findsOneWidget);
      expect(find.text('Your subjects'), findsOneWidget);
    });

    testWidgets('responsive layout across all device widths: 320dp, 360dp, 390dp, 412dp, 430dp', (tester) async {
      final sub1 = await SubjectController.instance.createSubject(
        name: 'Audit & Assurance',
      );
      final sub2 = await SubjectController.instance.createSubject(
        name: 'Business Law',
      );
      await ResourceController.instance.createResource(
        title: 'Audit Planning Matrix',
        resourceType: ResourceType.note,
        subjectId: sub1.id,
      );
      await ResourceController.instance.createResource(
        title: 'Contract Act Section 10',
        resourceType: ResourceType.note,
        subjectId: sub2.id,
      );

      const testWidths = [320.0, 360.0, 390.0, 412.0, 430.0];

      for (final width in testWidths) {
        await tester.pumpWidget(
          _buildTestApp(
            const ResourcesScreen(),
            size: Size(width, 700), // constrained height to test scrolling & overflow
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Your knowledge'), findsOneWidget);
        expect(find.text('New note'), findsOneWidget);
      }
    });

    testWidgets('scrolls smoothly to bottom without clipping or overflow', (tester) async {
      final sub = await SubjectController.instance.createSubject(name: 'Mathematics');

      for (int i = 1; i <= 10; i++) {
        await ResourceController.instance.createResource(
          title: 'Resource Item Number $i with detailed description',
          resourceType: ResourceType.note,
          subjectId: sub.id,
        );
      }

      await tester.pumpWidget(
        _buildTestApp(
          const ResourcesScreen(),
          size: const Size(360, 600),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Fling scroll down
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, -500), 1000);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
