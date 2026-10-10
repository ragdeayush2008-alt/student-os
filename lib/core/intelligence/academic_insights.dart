import 'package:flutter/foundation.dart';

import 'academic_context.dart';

/// Derived academic insights from existing controllers.
/// No persistence; derived only; explainable labels.
@immutable
class AcademicInsights {
  const AcademicInsights();

  static List<String> deriveFromContext(AcademicContext ctx) {
    final insights = <String>[];
    if (ctx.overdueTasks.isNotEmpty) {
      insights.add(
        'Overdue workload: ${ctx.overdueTasks.length} task${ctx.overdueTasks.length == 1 ? '' : 's'} need attention.',
      );
    }
    if (ctx.isWorkloadHeavy) {
      insights.add(
        'High workload this week — ${ctx.todayTasks.length + ctx.overdueTasks.length} pending tasks.',
      );
    }
    if (ctx.upcomingExams.isNotEmpty) {
      final near = ctx.examSummaries
          .where((e) => e.daysRemaining <= 7)
          .toList();
      if (near.isNotEmpty) {
        final earliest = near.reduce(
          (a, b) => a.daysRemaining < b.daysRemaining ? a : b,
        );
        insights.add(
          'Exam approaching: ${earliest.exam.subject} in ${earliest.daysRemaining} day${earliest.daysRemaining == 1 ? '' : 's'}. ${earliest.explanation}',
        );
      }
    }
    if (ctx.highPressureSubjectIds.isNotEmpty) {
      insights.add(
        'High-exam-pressure subjects: ${ctx.highPressureSubjectIds.join(', ')}.',
      );
    }
    if (ctx.neglectedSubjectIds.isNotEmpty) {
      insights.add(
        'Subjects needing attention: ${ctx.neglectedSubjectIds.join(', ')}.',
      );
    }
    if (insights.isEmpty) {
      insights.add('Academic workload is balanced.');
    }
    return insights;
  }
}
