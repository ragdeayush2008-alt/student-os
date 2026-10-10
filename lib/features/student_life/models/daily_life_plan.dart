import 'package:flutter/foundation.dart';

import 'life_routine_item.dart';

@immutable
class DailyLifePlan {
  const DailyLifePlan({
    required this.day,
    required this.sleepWindowStart,
    required this.sleepWindowEnd,
    required this.targetSleepMinutes,
    required this.items,
    required this.studyTargetMinutes,
    required this.scheduledStudyMinutes,
    required this.generatedAt,
    this.latestStudyEnd,
    this.warnings = const [],
    this.reducedOptionalCount = 0,
    this.fixedCommitmentCount = 0,
    this.fixedCommitmentTitles = const [],
    this.droppedEssentialCount = 0,
  });

  final DateTime day;
  final DateTime sleepWindowStart;
  final DateTime sleepWindowEnd;
  final int targetSleepMinutes;
  final List<LifeRoutineItem> items;
  final int studyTargetMinutes;
  final int scheduledStudyMinutes;
  final DateTime generatedAt;
  final DateTime? latestStudyEnd;
  final List<String> warnings;
  final int reducedOptionalCount;
  final int fixedCommitmentCount;
  final List<String> fixedCommitmentTitles;
  final int droppedEssentialCount;

  int get sleepWindowMinutes {
    final diff = sleepWindowEnd.difference(sleepWindowStart).inMinutes;
    return diff > 0 ? diff : 0;
  }

  int get sleepDeficitMinutes {
    final deficit = targetSleepMinutes - sleepWindowMinutes;
    return deficit > 0 ? deficit : 0;
  }

  bool get hasWarnings => warnings.isNotEmpty;

  bool get studiesIntoSleep {
    final end = latestStudyEnd;
    if (end == null) return false;
    return end.isAfter(sleepWindowStart);
  }

  List<LifeRoutineItem> get routineItems =>
      items.where((i) => i.kind != LifeRoutineKind.studyTarget).toList();

  List<LifeRoutineItem> get optionalItems =>
      items.where((i) => i.isOptional).toList();

  int get completedRoutineCount =>
      routineItems.where((i) => i.isCompleted).length;

  bool get isEmpty => items.isEmpty;
}
