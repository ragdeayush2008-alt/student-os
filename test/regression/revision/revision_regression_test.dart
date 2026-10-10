import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/data/models/revision_record.dart';
import 'package:student_os/data/models/revision_schedule.dart';
import 'package:student_os/data/models/xp_event.dart';
import 'package:student_os/features/progression/progression_controller.dart';
import 'package:student_os/features/revision/revision_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('user_regression_rev');
    RevisionController.instance.clearData();
    ProgressionController.instance.clearData();
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('Revision Regression Tests', () {
    test('1. RevisionRecord backward compatibility with minimal JSON', () {
      final json = <String, dynamic>{
        'id': 'rev_leg_1',
        'topicId': 'top_legacy',
        'durationSec': 900,
      };

      final record = RevisionRecord.fromJson(json);
      expect(record.id, 'rev_leg_1');
      expect(record.topicId, 'top_legacy');
      expect(record.durationSec, 900);
      expect(record.recallOutcome, RevisionRecallOutcome.unassessed);
      expect(record.notes, '');
      expect(record.source, 'session');
    });

    test('2. RevisionSchedule backward compatibility with minimal JSON', () {
      final json = <String, dynamic>{
        'id': 'sched_leg_1',
        'topicId': 'top_leg_sched',
      };

      final sched = RevisionSchedule.fromJson(json);
      expect(sched.id, 'sched_leg_1');
      expect(sched.topicId, 'top_leg_sched');
      expect(sched.state, RevisionState.newTopic);
      expect(sched.intervalDays, 1);
      expect(sched.revisionCount, 0);
      expect(sched.easeFactor, 2.5);
    });

    test('3. Revision XP is strictly idempotent and cannot be double-credited', () async {
      final record = await RevisionController.instance.recordRevision(
        topicId: 'top_xp_dup',
        durationSec: 600,
        recallOutcome: RevisionRecallOutcome.knew,
      );

      final eventId = 'xp_revision_${record.id}';
      final initialCount = ProgressionController.instance.events.where((e) => e.id == eventId).length;
      expect(initialCount, 1);

      final duplicateAccepted = await ProgressionController.instance.recordEvent(
        XpEvent(
          id: eventId,
          type: XpEventType.studySessionCompleted,
          amount: 25,
          reason: 'Duplicate revision test',
          timestamp: DateTime.now(),
        ),
      );

      expect(duplicateAccepted, isFalse);
      final afterCount = ProgressionController.instance.events.where((e) => e.id == eventId).length;
      expect(afterCount, 1);
    });

    test('4. Unknown identity does not persist data', () async {
      AuthIsolation.instance.clearSession();
      RevisionController.instance.clearData();

      expect(AuthIsolation.resolveUserId(null), isNull);
    });
  });
}
