import 'package:flutter/material.dart';

import '../../features/goals/goal_controller.dart';
import '../tasks/task_controller.dart';

/// Truthful goal progress — derived only from real controllers.
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = GoalController.instance;
    final tc = TaskController.instance;
    final completed = tc.completedCount;
    final target = gc.weeklyTaskTarget;
    final progress = target > 0 ? completed / target : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('My Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text('Weekly task target: $target'),
                subtitle: Text('$completed completed'),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.clamp(0, 1).toDouble()),
            const SizedBox(height: 8),
            Text('${(progress * 100).round()}% — derived from real tasks'),
            const SizedBox(height: 16),
            Text('Daily study target: ${gc.dailyStudyTarget.inMinutes} min'),
          ],
        ),
      ),
    );
  }
}
