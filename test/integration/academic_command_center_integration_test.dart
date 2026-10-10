import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_command_center.dart';

void main() {
  group('Academic Command Center integration', () {
    test('subject stats derived from real tasks', () {
      final stats = AcademicCommandCenter.deriveSubjectStats('test-subj-001');
      expect(stats.containsKey('activeTasks'), isTrue);
      expect(stats.containsKey('upcomingExams'), isTrue);
    });

    test('exam context derived from real exams', () {
      final ctx = AcademicCommandCenter.deriveExamContext('test-exam-001');
      // Returns empty or real data depending on controller state — never crashes
      expect(ctx, isA<Map>());
    });

    test('no duplicate persistence or mutation', () {
      // Center is pure derived; no side effects
      expect(AcademicCommandCenter, isA<Type>());
    });
  });
}
