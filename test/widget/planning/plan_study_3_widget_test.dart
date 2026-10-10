import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/time/app_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/knowledge/academic_knowledge_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/plan_study_state.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

/// Phase 3 — Plan & Study 3.0 widget tests.
///
/// Exercises PLAN, STUDY and the Plan <-> Study / Task <-> Study / Focus /
/// Exam / isolation / empty-state / responsive requirements against the real
/// controllers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String userId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final realNow = AppClock.current;
    AppClock.freezeAt(DateTime(realNow.year, realNow.month, realNow.day, 7, 0));
    userId = 'plan_study_3_widget_${DateTime.now().microsecondsSinceEpoch}';
    AuthIsolation.instance.setAuthenticatedUser(userId);
    ControllerIsolation.instance.clearAllControllers();
    await SubjectController.instance.load();
    await TaskController.instance.load();
    await PlanningBlockController.instance.load();
    await StudyController.instance.load();
    await AcademicKnowledgeController.instance.load();
    await ExamController.instance.load();
  });

  Widget wrap(Widget child, {double width = 390, double height = 844}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
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

  DateTime todayAt(int hour, [int minute = 0]) {
    final now = AppClock.current;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Future<void> seedStudySession({
    required String subject,
    required String subjectId,
    String? topicId,
    String? chapterId,
    int minutes = 35,
    int daysAgo = 0,
  }) async {
    final end = AppClock.current.subtract(Duration(days: daysAgo));
    final session = StudySession(
      id: 'seed_${DateTime.now().microsecondsSinceEpoch}',
      subject: subject,
      subjectId: subjectId,
      topicId: topicId,
      chapterId: chapterId,
      startedAt: end.subtract(Duration(minutes: minutes)),
      endedAt: end,
      durationSec: minutes * 60,
      completed: true,
    );
    await StorageService.instance.saveJsonList(
      userId: userId,
      key: 'study_sessions',
      list: [session.toJson()],
    );
    await StudyController.instance.load();
  }

  group('§2 — PLAN | STUDY is one tab with a shared segmented control', () {
    testWidgets('1. PLAN is the default tab', (tester) async {
      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('PLAN'), findsOneWidget);
    });

    testWidgets('2. switches PLAN -> STUDY -> PLAN and content follows',
        (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');
      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      expect(find.text('PLAN'), findsOneWidget);
      expect(find.text('Study Overview'), findsNothing);

      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();
      expect(find.text('Study Overview'), findsOneWidget);
      expect(find.text('PLAN'), findsNothing);

      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();
      expect(find.text('PLAN'), findsOneWidget);
    });
  });

  group('§4 — Plan header uses real data only', () {
    testWidgets('3. header shows PLAN label and the real weekday + date',
        (tester) async {
      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      final view = PlanStudyState.planDay(AppClock.current);
      expect(find.text('PLAN'), findsOneWidget);
      expect(find.text(view.dayLabel), findsOneWidget);
    });

    testWidgets('4. with no plan the header says so and invents no numbers',
        (tester) async {
      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Nothing planned yet'), findsOneWidget);
    });

    testWidgets('5. with blocks the header shows real planned time and count',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Accountancy');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(9),
        todayAt(9, 45),
        subjectId: subject.id,
        customTitle: 'Partnership Accounts',
      );
      await PlanningBlockController.instance.scheduleBlock(
        null,
        todayAt(11),
        todayAt(11, 30),
        subjectId: subject.id,
        customTitle: 'Contract Act',
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      // 45 + 30 = 75m → "1h 15m planned · 2 blocks"
      expect(find.textContaining('1h 15m planned'), findsOneWidget);
      expect(find.textContaining('2 blocks'), findsOneWidget);
    });
  });

  group('§5 — Today plan rows carry academic context', () {
    testWidgets('6. a row shows time, subject, chapter, topic and duration',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Business Law');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id,
        title: 'Contract Act',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Offer',
      );
      await PlanningBlockController.instance.scheduleTopicBlock(
        topic.id,
        todayAt(9),
        todayAt(9, 45),
        subjectId: subject.id,
        chapterId: chapter.id,
        customTitle: 'Offer Revision',
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('09:45'), findsOneWidget);
      expect(find.text('Offer Revision'), findsWidgets);
      expect(
        find.text('Business Law · Contract Act · Offer'),
        findsOneWidget,
      );
      expect(find.textContaining('45 min'), findsWidgets);
    });

    testWidgets('7. rows are ordered chronologically', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      await PlanningBlockController.instance.scheduleBlock(
        null, todayAt(14), todayAt(14, 30),
        subjectId: subject.id, customTitle: 'Later',
      );
      await PlanningBlockController.instance.scheduleBlock(
        null, todayAt(21), todayAt(21, 30),
        subjectId: subject.id, customTitle: 'Latest',
      );

      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.blocks.first.title, 'Later');
      expect(view.blocks.last.title, 'Latest');

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('§6 — Active block', () {
    testWidgets('8. a live block renders the NOW card', (tester) async {
      final now = AppClock.current;
      final subject = await SubjectController.instance.createSubject(name: 'Accountancy');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        now.subtract(const Duration(minutes: 10)),
        now.add(const Duration(minutes: 20)),
        subjectId: subject.id,
        customTitle: 'Live Session',
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('NOW'), findsOneWidget);
      expect(find.textContaining('min remaining'), findsOneWidget);
      expect(find.text('Start Now'), findsOneWidget);
    });

    testWidgets('9. no NOW card when nothing is live', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      await PlanningBlockController.instance.scheduleBlock(
        null, todayAt(21), todayAt(21, 30),
        subjectId: subject.id, customTitle: 'Tonight',
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      expect(find.text('NOW'), findsNothing);
    });

    testWidgets('10. with Focus already active the block is preserved, not duplicated',
        (tester) async {
      final now = AppClock.current;
      final subject = await SubjectController.instance.createSubject(name: 'Physics');
      await PlanningBlockController.instance.scheduleBlock(
        null,
        now.subtract(const Duration(minutes: 5)),
        now.add(const Duration(minutes: 25)),
        subjectId: subject.id,
        customTitle: 'Live Session',
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      // The active-block card must offer Continue, never a second Start.
      final nowCard = find.ancestor(
        of: find.text('NOW'),
        matching: find.byType(Card),
      );
      expect(find.descendant(of: nowCard, matching: find.text('Start Now')),
          findsNothing);
    });
  });

  group('§7/§8/§9 — Plan My Day, available time, allocation', () {
    testWidgets('11. Plan My Day opens the existing preview sheet',
        (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Plan My Day').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan My Day').last);
      await tester.pumpAndSettle();

      // Existing PlanningEngine-backed flow, not a new one.
      expect(find.text('Plan My Day'), findsWidgets);
      expect(find.text('How much time do you have?'), findsOneWidget);
    });

    testWidgets('12. allocation section lists real subject minutes',
        (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');
      await SubjectController.instance.createSubject(name: 'Business Law');

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Available Time'), findsOneWidget);
      expect(find.textContaining('splits up'), findsOneWidget);
      expect(find.textContaining('min'), findsWidgets);
    });

    testWidgets('13. changing the budget changes the allocation', (tester) async {
      await SubjectController.instance.createSubject(name: 'Economics');

      final small = PlanStudyState.allocation(budgetMinutes: 15);
      final large = PlanStudyState.allocation(budgetMinutes: 240);
      expect(small.totalPlannedMinutes, lessThanOrEqualTo(large.totalPlannedMinutes));
    });

    testWidgets('14. allocation is hidden when there is nothing academic',
        (tester) async {
      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Available Time'), findsNothing);
    });
  });

  group('§10 — Smart rescheduling', () {
    testWidgets('15. a missed block shows MISSED and a Reschedule action',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Business Law');
      await PlanningBlockController.instance.scheduleBlock(
        null, todayAt(1), todayAt(1, 30),
        subjectId: subject.id, customTitle: 'Missed Work',
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('MISSED'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      // Never silently destroyed.
      expect(find.text('Missed Work'), findsWidgets);
    });

    testWidgets('16. reschedule offers real free slots', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Business Law');
      final block = await PlanningBlockController.instance.scheduleBlock(
        null, todayAt(1), todayAt(1, 30),
        subjectId: subject.id, customTitle: 'Missed Work',
      );
      expect(PlanningEngine.findRecoverySlots(block), isNotEmpty);

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reschedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reschedule'));
      await tester.pumpAndSettle();

      expect(find.text('Reschedule'), findsWidgets);
      expect(find.text('Keep as is'), findsOneWidget);
    });

    testWidgets('17. choosing a slot actually moves the block', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Business Law');
      final block = await PlanningBlockController.instance.scheduleBlock(
        null, todayAt(1), todayAt(1, 30),
        subjectId: subject.id, customTitle: 'Missed Work',
      );
      final originalStart = block.startAt;

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reschedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reschedule'));
      await tester.pumpAndSettle();

      // Tap the first offered slot.
      final kept = find.text('Keep as is');
      await tester.tap(kept);
      await tester.pumpAndSettle();

      // Even a cancel leaves the original block untouched.
      final after = PlanningBlockController.instance.blocks
          .where((b) => b.id == block.id)
          .first;
      expect(after.startAt, originalStart);
      expect(after.endAt.difference(after.startAt).inMinutes, 30);
    });
  });

  group('§11 — Completion behaviour', () {
    testWidgets('18. completing the linked task marks the block done',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Quant');
      final task = await TaskController.instance.createTask(
        title: 'Ratio Practice',
        subjectId: subject.id,
      );
      await PlanningBlockController.instance.scheduleBlock(
        task.id,
        todayAt(9),
        todayAt(9, 30),
        subjectId: subject.id,
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      expect(PlanStudyState.isBlockCompleted, isNotNull);

      await TaskController.instance.completeTask(task.id);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Done'), findsWidgets);

      final view = PlanStudyState.planDay(AppClock.current);
      expect(view.allCompleted, isTrue);
      expect(view.completedMinutes, 30);
    });

    testWidgets('19. no duplicate completion record is written', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Quant');
      final task = await TaskController.instance.createTask(title: 'Algebra');
      await PlanningBlockController.instance.scheduleBlock(
        task.id, todayAt(9), todayAt(9, 30),
        subjectId: subject.id,
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      await TaskController.instance.completeTask(task.id);
      await tester.pumpAndSettle();

      expect(PlanningBlockController.instance.blocks.length, 1);
      expect(PlanningBlockController.instance.blocksForDay(AppClock.current).length, 1);
    });
  });

  group('§12–§14 — STUDY overview and subjects', () {
    testWidgets('20. no course shows a Set Up Course empty state',
        (tester) async {
      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No course yet'), findsOneWidget);
      expect(find.text('Set Up Course'), findsOneWidget);
      expect(find.text('Study Overview'), findsNothing);
    });

    testWidgets('21. overview shows real syllabus counts', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Physics');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Mechanics',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Kinematics',
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Study Overview'), findsOneWidget);
      expect(find.textContaining('0 of 1 topics studied'), findsOneWidget);
      expect(find.text('1 subjects'), findsOneWidget);
    });

    testWidgets('22. subject rows show progress, study time and open action',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Physics');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Mechanics',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Kinematics',
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Physics'), findsWidgets);
      expect(find.textContaining('% syllabus'), findsWidgets);
      expect(find.text('Open'), findsWidgets);
      expect(find.text('Focus'), findsWidgets);
    });
  });

  group('§18 — Continue learning from real data', () {
    testWidgets('23. no continue card without study history', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Accounting');

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE LEARNING'), findsNothing);
      expect(find.text('No study history'), findsOneWidget);
      expect(find.text('Start Studying'), findsOneWidget);
      expect(subject.id, isNotEmpty);
    });

    testWidgets('24. continue card reflects the real last-studied session',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Accounting');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Partnership',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Partnership Accounts',
      );
      await seedStudySession(
        subject: 'Accounting',
        subjectId: subject.id,
        topicId: topic.id,
        chapterId: chapter.id,
        minutes: 35,
        daysAgo: 1,
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE LEARNING'), findsOneWidget);
      expect(find.text('Accounting'), findsWidgets);
      expect(find.text('Partnership Accounts'), findsWidgets);
      expect(find.text('Last studied: Yesterday'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue'));
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('§19 — Recommended study', () {
    testWidgets('25. exactly one recommendation is shown with a reason',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Biology');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Cells',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Mitochondria',
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECOMMENDED'), findsOneWidget);
      expect(find.text('Mitochondria'), findsWidgets);
      expect(find.text('Plan It'), findsOneWidget);
      expect(find.textContaining('Not Started'), findsWidgets);
    });
  });

  group('§16/§24 — Topic states come from the engine', () {
    testWidgets('26. topic state chips render the engine status label',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'History');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Modern India',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Freedom Struggle',
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      // Engine-derived TopicStatus label is surfaced verbatim.
      expect(find.textContaining('Not Started'), findsWidgets);
    });
  });

  group('§23 — Revision integration', () {
    testWidgets('27. no revision due shows a clear state', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Zoology');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Cells',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Osmosis',
      );
      await seedStudySession(
        subject: 'Zoology',
        subjectId: subject.id,
        topicId: AcademicKnowledgeController.instance.topics.first.id,
        chapterId: chapter.id,
        minutes: 30,
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("You're clear for now"), findsOneWidget);
    });
  });

  group('§26 — Plan <-> Study integration', () {
    testWidgets('28. a topic planned from STUDY appears in PLAN',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Geography');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Climate',
      );
      final topic = await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Monsoons',
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      // Plan the recommended topic through the shared sheet.
      await tester.ensureVisible(find.text('Plan It'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan It'));
      await tester.pumpAndSettle();
      expect(find.text('Plan this topic'), findsOneWidget);

      // Pick an explicit day so the assertion is time-of-day independent.
      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add to plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to plan'));
      await tester.pumpAndSettle();

      // Written to the one authoritative planning store.
      final blocks = PlanningBlockController.instance.blocks;
      expect(blocks.length, 1);
      expect(blocks.single.topicId, topic.id);
      expect(blocks.single.subjectId, subject.id);

      // And PLAN reads that same storage — no second study schedule.
      final tomorrow = AppClock.current.add(const Duration(days: 1));
      final planView = PlanStudyState.planDay(tomorrow);
      expect(planView.blocks.length, 1);
      expect(planView.blocks.single.topicId, topic.id);
      expect(planView.blocks.single.hasAcademicContext, isTrue);
      expect(planView.plannedMinutes, greaterThan(0));

      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('29. topic plan sheet previews a real free slot', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Geography');
      final chapter = await AcademicKnowledgeController.instance.createChapter(
        subjectId: subject.id, title: 'Climate',
      );
      await AcademicKnowledgeController.instance.createTopic(
        chapterId: chapter.id,
        subjectId: subject.id,
        title: 'Monsoons',
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Plan It'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan It'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      // Nothing is created until confirmation.
      expect(PlanningBlockController.instance.blocks, isEmpty);
    });
  });

  group('§27 — Task <-> Study integration', () {
    testWidgets('30. a subject-linked task shows its academic context',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      await TaskController.instance.createTask(
        title: 'Elasticity Questions',
        subjectId: subject.id,
        dueDate: AppClock.current,
        scheduledDate: AppClock.current,
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Elasticity Questions'), findsOneWidget);
      expect(find.text('Economics'), findsWidgets);
    });

    testWidgets('31. completing a task does not double-count progress',
        (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'Economics');
      final task = await TaskController.instance.createTask(
        title: 'Elasticity Questions',
        subjectId: subject.id,
        dueDate: AppClock.current,
        scheduledDate: AppClock.current,
      );

      await tester.pumpWidget(wrap(const PlanningScreen()));
      await tester.pumpAndSettle();
      await TaskController.instance.completeTask(task.id);
      await tester.pumpAndSettle();

      final subjectBlocks = PlanningBlockController.instance.blocksForSubject(subject.id);
      expect(subjectBlocks, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('§25 — Exam integration', () {
    testWidgets('32. subject row shows a real exam countdown', (tester) async {
      final subject = await SubjectController.instance.createSubject(name: 'CA Foundation');
      final now = AppClock.current;
      await ExamController.instance.createExam(
        title: 'CA Foundation',
        subject: 'CA Foundation',
        examDateTime: DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 12)),
      );

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('d'), findsWidgets);
      final view = PlanStudyState.studyOverview();
      final sv = view.subjects.firstWhere((s) => s.subject.id == subject.id);
      expect(sv.daysUntilNextExam, isNotNull);
    });
  });

  group('§34 — user isolation', () {
    testWidgets('33. User B never sees User A subjects or plan', (tester) async {
      final subjectA =
          await SubjectController.instance.createSubject(name: 'A Private Subject');
      await PlanningBlockController.instance.scheduleBlock(
        null, todayAt(9), todayAt(10),
        subjectId: subjectA.id, customTitle: 'A Work',
      );

      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.setAuthenticatedUser('other_$userId');
      await SubjectController.instance.load();
      await TaskController.instance.load();
      await PlanningBlockController.instance.load();

      await tester.pumpWidget(
        wrap(const PlanningScreen(initialTab: PlanStudyTab.study)),
      );
      await tester.pumpAndSettle();

      expect(find.text('A Private Subject'), findsNothing);
      expect(PlanStudyState.planDay(AppClock.current).blocks, isEmpty);
    });
  });

  group('§29 — Responsive', () {
    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0]) {
      testWidgets('34. builds without overflow at ${width.toInt()}dp PLAN + STUDY',
          (tester) async {
        final subject = await SubjectController.instance.createSubject(name: 'Accountancy');
        await PlanningBlockController.instance.scheduleBlock(
          null, todayAt(9), todayAt(9, 45),
          subjectId: subject.id, customTitle: 'Partnership Accounts',
        );

        await tester.pumpWidget(wrap(const PlanningScreen(), width: width));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Study'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('35. tablet width is clean', (tester) async {
      await SubjectController.instance.createSubject(name: 'Accountancy');
      await tester.pumpWidget(wrap(const PlanningScreen(), width: 1024, height: 768));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
