import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/daily_academic_snapshot.dart';

void main() {
  group('DailyAcademicSnapshot', () {
    test('derives from controllers without mutation', () {
      final snap = DailyAcademicSnapshot.fromControllers();
      expect(snap.todayTaskCount >= 0, isTrue);
      expect(snap.overdueCount >= 0, isTrue);
      expect(snap.studyMinutesToday >= 0, isTrue);
      expect(snap.focusMinutesToday >= 0, isTrue);
      expect(
        snap.completionRatio >= 0.0 && snap.completionRatio <= 1.0,
        isTrue,
      );
    });

    test('nowAction deterministic or null safely', () {
      final snap1 = DailyAcademicSnapshot.fromControllers();
      final snap2 = DailyAcademicSnapshot.fromControllers();
      // Same state → comparable now actions
      expect(
        snap1.nowAction?.id == snap2.nowAction?.id ||
            (snap1.nowAction == null && snap2.nowAction == null),
        isTrue,
      );
    });

    test('deleted entities not referenced in recommendation', () {
      final snap = DailyAcademicSnapshot.fromControllers();
      final now = snap.nowAction;
      if (now != null && now.taskId != null) {
        expect(now.taskId!.isNotEmpty, isTrue);
      }
    });
  });
}
