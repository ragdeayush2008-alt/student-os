import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/navigation/shell_destinations.dart';
import 'package:student_os/features/tools/presentation/tools_hub_screen.dart';

void main() {
  group('Tools Hub — Unit Tests', () {
    test('ShellDestinations has exactly 5 locked destinations', () {
      expect(ShellDestinations.all.length, 5);
      expect(ShellDestinations.all[0].title, 'Home');
      expect(ShellDestinations.all[1].title, 'Plan & Study');
      expect(ShellDestinations.all[2].title, 'SprintX');
      expect(ShellDestinations.all[3].title, 'Tools Hub');
      expect(ShellDestinations.all[4].title, 'Workspace');
    });

    test('ShellDestinations 4th tab is Tools Hub with route /tools', () {
      final toolsDest = ShellDestinations.all[3];
      expect(toolsDest.title, 'Tools Hub');
      expect(toolsDest.route, '/tools');
    });

    test('ToolCategory enum has all expected category partitions', () {
      expect(ToolCategory.values, contains(ToolCategory.all));
      expect(ToolCategory.values, contains(ToolCategory.intelligence));
      expect(ToolCategory.values, contains(ToolCategory.knowledge));
      expect(ToolCategory.values, contains(ToolCategory.practice));
      expect(ToolCategory.values, contains(ToolCategory.schedule));
      expect(ToolCategory.values, contains(ToolCategory.focus));
      expect(ToolCategory.values, contains(ToolCategory.utilities));
      expect(ToolCategory.values, contains(ToolCategory.settings));
    });

    test('ToolItem model initializes with valid fields', () {
      final item = ToolItem(
        id: 'test_tool',
        title: 'Test Tool',
        subtitle: 'Test tool description',
        icon: ToolCategory.intelligence.icon,
        category: ToolCategory.intelligence,
        tags: const ['test', 'tool', 'ai'],
        onTap: (_) {},
      );

      expect(item.id, 'test_tool');
      expect(item.title, 'Test Tool');
      expect(item.subtitle, 'Test tool description');
      expect(item.category, ToolCategory.intelligence);
      expect(item.tags, contains('ai'));
      expect(item.isInteractive, isFalse);
    });
  });
}
