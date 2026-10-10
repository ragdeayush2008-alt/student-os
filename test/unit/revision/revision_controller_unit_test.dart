import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/revision_record.dart';
import 'package:student_os/data/models/revision_schedule.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/revision/revision_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_test_rev_ctrl');
    RevisionController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('RevisionController Unit Tests', () {
    test('1. recordRevision stores record, updates schedule, and awards XP idempotently', () async {
      final controller = RevisionController.instance;

      final record = await controller.recordRevision(
        topicId: 'top_test_1',
        chapterId: 'ch_1',
        subjectId: 'sub_1',
        durationSec: 1200,
        recallOutcome: RevisionRecallOutcome.knew,
        notes: 'Great recall',
      );

      expect(controller.records.length, 1);
      expect(controller.recordsForTopic('top_test_1').length, 1);
      expect(controller.recordsForSubject('sub_1').length, 1);
      expect(controller.totalRevisionMinutes, 20);
      expect(controller.completedRevisionSessionsCount, 1);

      // Check Schedule updated
      final schedule = controller.scheduleForTopic('top_test_1');
      expect(schedule, isNotNull);
      expect(schedule!.revisionCount, 1);
      expect(schedule.successfulRecallCount, 1);
      expect(schedule.intervalDays, 3);
      expect(schedule.state, RevisionState.learning);

      // Check XP Event
      final xpEvents = ProgressionController.instance.events;
      expect(xpEvents.any((e) => e.id == 'xp_revision_${record.id}'), isTrue);
    });

    test('2. Second successful revision expands schedule to 7 days', () async {
      final controller = RevisionController.instance;

      await controller.recordRevision(
        topicId: 'top_test_2',
        durationSec: 900,
        recallOutcome: RevisionRecallOutcome.knew,
      );

      await controller.recordRevision(
        topicId: 'top_test_2',
        durationSec: 900,
        recallOutcome: RevisionRecallOutcome.knew,
      );

      final schedule = controller.scheduleForTopic('top_test_2');
      expect(schedule!.revisionCount, 2);
      expect(schedule.intervalDays, 7);
      expect(schedule.state, RevisionState.stable);
    });

    test('3. Failed revision resets schedule interval to 1 day', () async {
      final controller = RevisionController.instance;

      await controller.recordRevision(
        topicId: 'top_test_3',
        durationSec: 600,
        recallOutcome: RevisionRecallOutcome.knew,
      );

      await controller.recordRevision(
        topicId: 'top_test_3',
        durationSec: 600,
        recallOutcome: RevisionRecallOutcome.forgot,
      );

      final schedule = controller.scheduleForTopic('top_test_3');
      expect(schedule!.intervalDays, 1);
      expect(schedule.failedRecallCount, 1);
      expect(schedule.state, RevisionState.learning);
    });

    test('4. User isolation: User A revision records are invisible to User B', () async {
      final controller = RevisionController.instance;

      // User A records revision
      AuthIsolation.instance.setAuthenticatedUser('user_A_rev');
      await controller.recordRevision(
        topicId: 'top_user_a',
        notes: 'User A exclusive revision',
      );
      expect(controller.records.length, 1);
      expect(controller.records.first.notes, 'User A exclusive revision');

      // User B logs in
      AuthIsolation.instance.setAuthenticatedUser('user_B_rev');
      ControllerIsolation.instance.clearAllControllers();
      await controller.load();

      expect(controller.records, isEmpty);
      expect(controller.schedules, isEmpty);

      // User B records their own revision
      await controller.recordRevision(
        topicId: 'top_user_b',
        notes: 'User B revision',
      );
      expect(controller.records.length, 1);
      expect(controller.records.first.notes, 'User B revision');

      // User A logs back in
      AuthIsolation.instance.setAuthenticatedUser('user_A_rev');
      ControllerIsolation.instance.clearAllControllers();
      await controller.load();

      expect(controller.records.length, 1);
      expect(controller.records.first.notes, 'User A exclusive revision');
    });
  });
}
