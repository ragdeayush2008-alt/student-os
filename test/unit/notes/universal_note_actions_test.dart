import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/navigation/universal_action_executor.dart';

void main() {
  group('UniversalActionExecutor Note Actions Tests', () {
    test('1. noteActions returns all essential actions for an unpinned active note', () {
      final actions = UniversalActionExecutor.noteActions(
        isPinned: false,
        isArchived: false,
        hasTopic: true,
      );

      final ids = actions.map((a) => a.id).toSet();

      expect(ids.contains(UniversalNoteAction.open), isTrue);
      expect(ids.contains(UniversalNoteAction.edit), isTrue);
      expect(ids.contains(UniversalNoteAction.focus), isTrue);
      expect(ids.contains(UniversalNoteAction.study), isTrue);
      expect(ids.contains(UniversalNoteAction.practice), isTrue);
      expect(ids.contains(UniversalNoteAction.revise), isTrue);
      expect(ids.contains(UniversalNoteAction.plan), isTrue);
      expect(ids.contains(UniversalNoteAction.pin), isTrue);
      expect(ids.contains(UniversalNoteAction.archive), isTrue);
      expect(ids.contains(UniversalNoteAction.delete), isTrue);

      final pinAction = actions.firstWhere((a) => a.id == UniversalNoteAction.pin);
      expect(pinAction.label, 'Pin');

      final archiveAction = actions.firstWhere((a) => a.id == UniversalNoteAction.archive);
      expect(archiveAction.label, 'Archive');
    });

    test('2. noteActions toggles Pin/Unpin and Archive/Restore labels based on state', () {
      final pinnedArchivedActions = UniversalActionExecutor.noteActions(
        isPinned: true,
        isArchived: true,
        hasTopic: false,
      );

      final pinAction = pinnedArchivedActions.firstWhere((a) => a.id == UniversalNoteAction.pin);
      expect(pinAction.label, 'Unpin');

      final archiveAction = pinnedArchivedActions.firstWhere((a) => a.id == UniversalNoteAction.archive);
      expect(archiveAction.label, 'Restore');

      // Notes without topic do not show topic practice/revise actions
      final ids = pinnedArchivedActions.map((a) => a.id).toSet();
      expect(ids.contains(UniversalNoteAction.practice), isFalse);
      expect(ids.contains(UniversalNoteAction.revise), isFalse);
    });
  });
}
