import 'package:flutter/foundation.dart';

enum LifeRoutineKind {
  wake('Wake up'),
  meal('Meal'),
  exercise('Exercise'),
  rest('Break'),
  hydration('Hydration'),
  windDown('Wind down'),
  bedtime('Bedtime'),
  nap('Nap'),
  studyTarget('Study target'),
  custom('Routine');

  const LifeRoutineKind(this.label);
  final String label;
}

@immutable
class LifeRoutineItem {
  const LifeRoutineItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.detail,
    this.isOptional = false,
    this.isCompleted = false,
    this.relatedBlockId,
  });

  final String id;
  final LifeRoutineKind kind;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? detail;
  final bool isOptional;
  final bool isCompleted;
  final String? relatedBlockId;

  int get durationMinutes {
    final diff = endAt.difference(startAt).inMinutes;
    return diff > 0 ? diff : 0;
  }

  LifeRoutineItem copyWith({
    bool? isCompleted,
    DateTime? startAt,
    DateTime? endAt,
    String? detail,
  }) {
    return LifeRoutineItem(
      id: id,
      kind: kind,
      title: title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      detail: detail ?? this.detail,
      isOptional: isOptional,
      isCompleted: isCompleted ?? this.isCompleted,
      relatedBlockId: relatedBlockId,
    );
  }
}
