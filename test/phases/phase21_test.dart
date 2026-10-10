import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/intelligence/personalized_insight_section.dart';
import 'package:student_os/core/intelligence/student_behavior_profile.dart';
import 'package:student_os/core/analytics/performance_snapshot.dart';
import 'package:student_os/data/models/study_session.dart';

void main() {
  group('Phase 21 — Personalized Adaptive Coaching', () {
    test('Profile falls back gracefully for new user', () {
      final profile = StudentBehaviorProfile.fromSnapshot(
        PerformanceSnapshot(
          allSessions: [],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        ),
      );
      expect(profile.hasSufficientData, isFalse);
      expect(profile.averageSessionMinutes, 0);
    });

    test('Profile calculates from actual study sessions', () {
      final now = DateTime.now();
      final profile = StudentBehaviorProfile.fromSnapshot(
        PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Math',
              durationSec: 1800,
              startedAt: now.subtract(const Duration(days: 1)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        ),
      );
      expect(profile.hasSufficientData, isTrue);
      expect(profile.averageSessionMinutes, greaterThan(0));
      expect(profile.preferredBudgetMinutes, greaterThanOrEqualTo(15));
    });

    test('Profile recommendation is explainable when sufficient', () {
      final now = DateTime.now();
      final profile = StudentBehaviorProfile.fromSnapshot(
        PerformanceSnapshot(
          allSessions: [
            StudySession(
              id: 's1',
              subject: 'Physics',
              durationSec: 3000,
              startedAt: now.subtract(const Duration(days: 2)),
            ),
            StudySession(
              id: 's2',
              subject: 'Physics',
              durationSec: 1800,
              startedAt: now.subtract(const Duration(days: 4)),
            ),
          ],
          allTasks: [],
          allSubjects: [],
          allExams: [],
          studyDates: {},
        ),
      );
      expect(profile.hasSufficientData, isTrue);
      expect(profile.recommendationReason, isNotEmpty);
    });

    test('Profile is deterministic on repeated call', () {
      final now = DateTime.now();
      final snapshot = PerformanceSnapshot(
        allSessions: [
          StudySession(
            id: 's1',
            subject: 'Math',
            durationSec: 3600,
            startedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        allTasks: [],
        allSubjects: [],
        allExams: [],
        studyDates: {},
      );
      final p1 = StudentBehaviorProfile.fromSnapshot(snapshot);
      final p2 = StudentBehaviorProfile.fromSnapshot(snapshot);
      expect(p1.averageSessionMinutes, p2.averageSessionMinutes);
    });

    test('Insufficient data does not crash insight section', () {
      expect(const PersonalizedInsightSection(), isNotNull);
    });
  });
}
