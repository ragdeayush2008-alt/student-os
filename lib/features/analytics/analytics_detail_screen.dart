import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../tasks/task_controller.dart';

class AnalyticsDetailScreen extends StatelessWidget {
  const AnalyticsDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tc = TaskController.instance;
    final completed = tc.tasks.where((t) => t.isCompleted).length;
    final total = tc.tasks.length;
    final pct = total > 0 ? (completed / total * 100).toStringAsFixed(0) : '0';
    return AppScaffold(
      title: 'Analytics',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(title: 'Task Completion', icon: Icons.check_circle_rounded),
            const SizedBox(height: AppSpacing.sm),
            Text('$completed / $total tasks completed ($pct%)', style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
