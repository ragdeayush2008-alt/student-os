import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/data/models/revision_queue_item.dart';
import 'package:student_os/data/models/revision_record.dart';
import 'package:student_os/data/models/revision_schedule.dart';
import 'package:student_os/data/models/topic.dart';

void main() {
  group('Revision Models Unit Tests', () {
    test('1. RevisionRecord serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 3, 16, 10, 0);
      final record = RevisionRecord(
        id: 'rev_1',
        userId: 'user_123',
        topicId: 'top_deprec',
        chapterId: 'ch_acc',
        subjectId: 'sub_acc',
        examId: 'exam_final',
        startedAt: now.subtract(const Duration(minutes: 20)),
        completedAt: now,
        durationSec: 1200,
        recallOutcome: RevisionRecallOutcome.knew,
        notes: 'Retained all key formulas',
        source: 'recall_session',
      );

      final json = record.toJson();
      final restored = RevisionRecord.fromJson(json);

      expect(restored.id, record.id);
      expect(restored.userId, record.userId);
      expect(restored.topicId, record.topicId);
      expect(restored.chapterId, record.chapterId);
      expect(restored.subjectId, record.subjectId);
      expect(restored.examId, record.examId);
      expect(restored.durationSec, 1200);
      expect(restored.durationMinutes, 20);
      expect(restored.recallOutcome, RevisionRecallOutcome.knew);
      expect(restored.isSuccessfulRecall, isTrue);
      expect(restored.notes, record.notes);
      expect(restored.source, 'recall_session');
      expect(restored, record);
    });

    test('2. RevisionRecord handles sparse and legacy JSON safely', () {
      final json = <String, dynamic>{
        'id': 'rev_sparse',
        'topicId': 'top_legacy',
      };

      final record = RevisionRecord.fromJson(json);
      expect(record.id, 'rev_sparse');
      expect(record.topicId, 'top_legacy');
      expect(record.durationSec, 0);
      expect(record.recallOutcome, RevisionRecallOutcome.unassessed);
      expect(record.notes, '');
      expect(record.source, 'session');
    });

    test('3. RevisionSchedule serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 3, 16, 12, 0);
      final nextRev = now.add(const Duration(days: 7));

      final schedule = RevisionSchedule(
        id: 'rev_sched_top_1',
        userId: 'user_123',
        topicId: 'top_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        examId: 'exam_1',
        state: RevisionState.stable,
        intervalDays: 7,
        lastRevisionAt: now,
        nextRevisionAt: nextRev,
        revisionCount: 2,
        successfulRecallCount: 2,
        failedRecallCount: 0,
        easeFactor: 2.6,
        priorityScore: 35.0,
        priorityReasons: ['Regular spaced review', 'Exam in 10 days'],
        suggestedDurationMinutes: 20,
      );

      final json = schedule.toJson();
      final restored = RevisionSchedule.fromJson(json);

      expect(restored.id, schedule.id);
      expect(restored.userId, schedule.userId);
      expect(restored.topicId, schedule.topicId);
      expect(restored.state, RevisionState.stable);
      expect(restored.intervalDays, 7);
      expect(restored.revisionCount, 2);
      expect(restored.successfulRecallCount, 2);
      expect(restored.failedRecallCount, 0);
      expect(restored.easeFactor, 2.6);
      expect(restored.priorityScore, 35.0);
      expect(restored.priorityReasons, schedule.priorityReasons);
      expect(restored.suggestedDurationMinutes, 20);
      expect(restored, schedule);
    });

    test('4. RevisionSchedule isDue and isOverdue calculate accurately', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final dueToday = RevisionSchedule(
        id: 'sched_due',
        topicId: 'top_due',
        nextRevisionAt: today,
        state: RevisionState.due,
      );
      expect(dueToday.isDue, isTrue);
      expect(dueToday.isOverdue, isFalse);

      final overdue = RevisionSchedule(
        id: 'sched_overdue',
        topicId: 'top_overdue',
        nextRevisionAt: today.subtract(const Duration(days: 3)),
        state: RevisionState.overdue,
      );
      expect(overdue.isDue, isTrue);
      expect(overdue.isOverdue, isTrue);

      final future = RevisionSchedule(
        id: 'sched_future',
        topicId: 'top_future',
        nextRevisionAt: today.add(const Duration(days: 5)),
        state: RevisionState.stable,
      );
      expect(future.isDue, isFalse);
      expect(future.isOverdue, isFalse);
    });

    test('5. RevisionQueueItem properties and helper getters', () {
      final topic = Topic(
        id: 'top_q',
        chapterId: 'ch_q',
        subjectId: 'sub_q',
        title: 'Queue Item Topic',
      );

      final sched = RevisionSchedule(
        id: 'sched_q',
        topicId: 'top_q',
        state: RevisionState.overdue,
      );

      final item = RevisionQueueItem(
        topic: topic,
        schedule: sched,
        state: RevisionState.overdue,
        dueCategory: RevisionDueCategory.overdue,
        priorityScore: 85.0,
        urgency: RecommendationUrgency.critical,
        title: 'Queue Item Topic',
        subjectName: 'Finance',
        reasons: ['Overdue by 4 days', 'Practice score: 45%'],
        suggestedDurationMinutes: 25,
        daysSinceLastRevision: 8,
        daysUntilNextRevision: -4,
        practiceAccuracy: 45,
        isWeak: true,
      );

      expect(item.isOverdue, isTrue);
      expect(item.isDueNow, isTrue);
      expect(item.topicId, 'top_q');
      expect(item.primaryReason, 'Overdue by 4 days');
      expect(item.isWeak, isTrue);
    });
  });
}
