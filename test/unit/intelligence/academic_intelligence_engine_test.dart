import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/academic_resource.dart';

void main() {
  final now = DateTime(2026, 9, 15, 10, 0);

  group('AcademicIntelligenceEngine — Exam Pressure (A)', () {
    test('Urgent exam with incomplete syllabus and zero study yields Critical pressure', () {
      final exam = StudentExam(
        id: 'exam_1',
        title: 'Accountancy Final',
        subject: 'Accountancy',
        examDateTime: now.add(const Duration(days: 1)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Topic 1', completed: false),
          SyllabusItem(id: 's2', title: 'Topic 2', completed: false),
        ],
      );

      final assessment = AcademicIntelligenceEngine.assessExamPressure(
        exam,
        sessions: const [],
        tasks: const [],
        referenceTime: now,
      );

      expect(assessment.level, equals(ExamPressureLevel.critical));
      expect(assessment.daysRemaining, equals(1));
      expect(assessment.syllabusRemainingCount, equals(2));
      expect(assessment.reasons, isNotEmpty);
    });

    test('Approaching exam (5 days) with some study yields High or Moderate pressure', () {
      final exam = StudentExam(
        id: 'exam_2',
        title: 'Economics Midterm',
        subject: 'Economics',
        examDateTime: now.add(const Duration(days: 5)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Micro', completed: true),
          SyllabusItem(id: 's2', title: 'Macro', completed: false),
        ],
      );

      final sessions = [
        StudySession(
          id: 'sess_1',
          subject: 'Economics',
          startedAt: now.subtract(const Duration(days: 2)),
          durationSec: 30 * 60,
          completed: true,
        ),
      ];

      final assessment = AcademicIntelligenceEngine.assessExamPressure(
        exam,
        sessions: sessions,
        tasks: const [],
        referenceTime: now,
      );

      expect(
        assessment.level == ExamPressureLevel.high ||
            assessment.level == ExamPressureLevel.moderate,
        isTrue,
      );
      expect(assessment.daysRemaining, equals(5));
      expect(assessment.recentStudyMinutes, equals(30));
    });

    test('Far-away exam (60 days) with full syllabus complete yields Low pressure', () {
      final exam = StudentExam(
        id: 'exam_3',
        title: 'History End Term',
        subject: 'History',
        examDateTime: now.add(const Duration(days: 60)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Modern History', completed: true),
        ],
      );

      final assessment = AcademicIntelligenceEngine.assessExamPressure(
        exam,
        sessions: const [],
        tasks: const [],
        referenceTime: now,
      );

      expect(assessment.level, equals(ExamPressureLevel.low));
      expect(assessment.daysRemaining, equals(60));
    });
  });

  group('AcademicIntelligenceEngine — Study Recommendations (B)', () {
    test('Neglected subject with upcoming exam is prioritized over recently studied subject', () {
      final subA = Subject(id: 'sub_a', name: 'Accountancy', preference: SubjectPreference.normal);
      final subB = Subject(id: 'sub_b', name: 'Economics', preference: SubjectPreference.normal);

      final examA = StudentExam(
        id: 'ex_a',
        title: 'Accountancy Exam',
        subject: 'Accountancy',
        examDateTime: now.add(const Duration(days: 4)),
      );

      // Economics was studied yesterday for 2 hours, Accountancy was not studied for 10 days
      final sessions = [
        StudySession(
          id: 's_b',
          subject: 'Economics',
          startedAt: now.subtract(const Duration(days: 1)),
          durationSec: 120 * 60,
          completed: true,
        ),
        StudySession(
          id: 's_a',
          subject: 'Accountancy',
          startedAt: now.subtract(const Duration(days: 10)),
          durationSec: 30 * 60,
          completed: true,
        ),
      ];

      final recs = AcademicIntelligenceEngine.generateStudyRecommendations(
        subjects: [subA, subB],
        exams: [examA],
        sessions: sessions,
        referenceTime: now,
      );

      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.subjectName, equals('Accountancy'));
      expect(recs.first.score, greaterThan(recs.last.score));
    });
  });

  group('AcademicIntelligenceEngine — Revision Recommendations (C)', () {
    test('Overdue topic with approaching exam is recommended with High or Critical urgency', () {
      final exam = StudentExam(
        id: 'ex_1',
        title: 'Law Exam',
        subject: 'Law',
        examDateTime: now.add(const Duration(days: 3)),
        syllabusItems: [
          SyllabusItem(
            id: 'top_1',
            title: 'Contracts Act',
            completed: true,
            completedAt: now.subtract(const Duration(days: 8)),
          ),
        ],
      );

      final revs = AcademicIntelligenceEngine.generateRevisionRecommendations(
        subjects: [Subject(id: 'sub_l', name: 'Law')],
        exams: [exam],
        sessions: const [],
        referenceTime: now,
      );

      expect(revs.isNotEmpty, isTrue);
      expect(revs.first.topicTitle, equals('Contracts Act'));
      expect(revs.first.urgency == RecommendationUrgency.critical ||
          revs.first.urgency == RecommendationUrgency.high, isTrue);
    });

    test('Revision resource tagged material is included in revision recommendations', () {
      final res = AcademicResource(
        id: 'res_1',
        title: 'Formulas Cheat Sheet',
        subjectId: 'sub_math',
        resourceType: ResourceType.revision,
        lastAccessedAt: now.subtract(const Duration(days: 9)),
      );

      final revs = AcademicIntelligenceEngine.generateRevisionRecommendations(
        subjects: [Subject(id: 'sub_math', name: 'Mathematics')],
        exams: const [],
        sessions: const [],
        resources: [res],
        referenceTime: now,
      );

      expect(revs.any((r) => r.resourceId == 'res_1'), isTrue);
    });
  });

  group('AcademicIntelligenceEngine — Unified Recommendation (D)', () {
    test('Produces exactly one top primary recommendation and alternatives', () {
      final subjects = [
        Subject(id: 's1', name: 'Math', preference: SubjectPreference.high),
        Subject(id: 's2', name: 'Physics', preference: SubjectPreference.normal),
        Subject(id: 's3', name: 'Chemistry', preference: SubjectPreference.low),
      ];

      final unified = AcademicIntelligenceEngine.generateUnifiedRecommendation(
        subjects: subjects,
        referenceTime: now,
      );

      expect(unified.hasRecommendation, isTrue);
      expect(unified.primary, isNotNull);
      expect(unified.primary!.subjectName, equals('Math'));
      expect(unified.alternatives.length, equals(2));
    });
  });

  group('AcademicIntelligenceEngine — Available-Time Allocation (E & F)', () {
    final sub1 = Subject(id: 's1', name: 'Accountancy', preference: SubjectPreference.high);
    final sub2 = Subject(id: 's2', name: 'Business Law', preference: SubjectPreference.normal);
    final sub3 = Subject(id: 's3', name: 'Economics', preference: SubjectPreference.normal);

    test('30 min budget allocates 1 focused block without breaks', () {
      final alloc = AcademicIntelligenceEngine.allocateStudyTime(
        availableMinutes: 30,
        subjects: [sub1, sub2, sub3],
        referenceTime: now,
      );

      expect(alloc.blocks.length, equals(1));
      expect(alloc.allocatedStudyMinutes, equals(30));
      expect(alloc.allocatedBreakMinutes, equals(0));
      expect(alloc.blocks.first.isBreak, isFalse);
    });

    test('60 min budget allocates focused study with rest/recall', () {
      final alloc = AcademicIntelligenceEngine.allocateStudyTime(
        availableMinutes: 60,
        subjects: [sub1, sub2, sub3],
        referenceTime: now,
      );

      expect(alloc.blocks.isNotEmpty, isTrue);
      expect(alloc.totalAvailableMinutes, equals(60));
      expect(alloc.allocatedStudyMinutes + alloc.allocatedBreakMinutes, equals(60));
    });

    test('2 hours (120 min) budget allocates multi-subject sessions with breaks', () {
      final alloc = AcademicIntelligenceEngine.allocateStudyTime(
        availableMinutes: 120,
        subjects: [sub1, sub2, sub3],
        referenceTime: now,
      );

      expect(alloc.blocks.length, greaterThanOrEqualTo(3));
      final breaks = alloc.blocks.where((b) => b.isBreak).toList();
      final study = alloc.blocks.where((b) => !b.isBreak).toList();

      expect(breaks.isNotEmpty, isTrue);
      expect(study.length, greaterThanOrEqualTo(2));
      expect(alloc.allocatedStudyMinutes, greaterThan(60));
    });

    test('3 hours (180 min) budget distributes across multiple subjects proportionally', () {
      final alloc = AcademicIntelligenceEngine.allocateStudyTime(
        availableMinutes: 180,
        subjects: [sub1, sub2, sub3],
        referenceTime: now,
      );

      expect(alloc.totalAvailableMinutes, equals(180));
      final study = alloc.blocks.where((b) => !b.isBreak).toList();
      expect(study.length, greaterThanOrEqualTo(3));
    });
  });

  group('AcademicIntelligenceEngine — Empty State & Backward Compatibility (I & J)', () {
    test('Empty state handles empty lists gracefully without throwing', () {
      final unified = AcademicIntelligenceEngine.generateUnifiedRecommendation(
        subjects: const [],
        exams: const [],
        sessions: const [],
        tasks: const [],
        resources: const [],
        referenceTime: now,
      );

      expect(unified.hasRecommendation, isFalse);
      expect(unified.primary, isNull);
      expect(unified.alternatives, isEmpty);
      expect(unified.revisionItems, isEmpty);
      expect(unified.activeExamsWithPressure, isEmpty);

      final alloc = AcademicIntelligenceEngine.allocateStudyTime(
        availableMinutes: 60,
        subjects: const [],
        referenceTime: now,
      );

      expect(alloc.blocks, isEmpty);
      expect(alloc.allocatedStudyMinutes, equals(0));
    });

    test('Backward compatibility: Subject and StudentExam from old JSON without new fields work safely', () {
      final oldSubjectJson = {
        'id': 'legacy_sub',
        'name': 'Mathematics',
      };
      final subj = Subject.fromJson(oldSubjectJson);
      expect(subj.id, equals('legacy_sub'));
      expect(subj.name, equals('Mathematics'));
      expect(subj.preference, equals(SubjectPreference.normal));

      final oldExamJson = {
        'id': 'legacy_exam',
        'title': 'Math Test',
      };
      final exam = StudentExam.fromJson(oldExamJson);
      expect(exam.id, equals('legacy_exam'));
      expect(exam.title, equals('Math Test'));
      expect(exam.status, equals(ExamStatus.upcoming));
      expect(exam.syllabusItems, isEmpty);

      final assessment = AcademicIntelligenceEngine.assessExamPressure(
        exam,
        referenceTime: now,
      );
      expect(assessment.level, equals(ExamPressureLevel.low));
    });
  });
}
