import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/features/checklist/checklist_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
  });

  group('ChecklistController — Unit Tests', () {
    test('1. Adds, toggles, edits, and deletes checklist items', () async {
      AuthIsolation.instance.setAuthenticatedUser('chk_user');
      final controller = ChecklistController.instance;
      await controller.load();

      expect(controller.items.isEmpty, isTrue);

      final item = await controller.addItem('Buy notebook');
      expect(controller.items.length, 1);
      expect(controller.pendingCount, 1);
      expect(item.isCompleted, isFalse);

      // Toggle completed
      await controller.toggleItem(item.id);
      expect(controller.items.first.isCompleted, isTrue);
      expect(controller.pendingCount, 0);

      // Edit item
      await controller.editItem(item.id, 'Buy 2 notebooks');
      expect(controller.items.first.title, 'Buy 2 notebooks');

      // Delete item
      await controller.deleteItem(item.id);
      expect(controller.items.isEmpty, isTrue);
    });

    test('2. Clear completed removes only completed items', () async {
      AuthIsolation.instance.setAuthenticatedUser('chk_user');
      final controller = ChecklistController.instance;
      await controller.load();

      final i1 = await controller.addItem('Item 1');
      await controller.addItem('Item 2');
      await controller.toggleItem(i1.id);

      expect(controller.items.length, 2);
      expect(controller.completedItems.length, 1);

      await controller.clearCompleted();
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Item 2');
    });

    test('3. Checklist is completely decoupled from TaskController', () async {
      AuthIsolation.instance.setAuthenticatedUser('chk_user');
      await TaskController.instance.load();
      await ChecklistController.instance.load();

      final initialTasks = TaskController.instance.tasks.length;

      final item = await ChecklistController.instance.addItem('Quick checklist note');
      await ChecklistController.instance.toggleItem(item.id);

      // Tasks must remain unaffected
      expect(TaskController.instance.tasks.length, initialTasks);
    });
  });
}
