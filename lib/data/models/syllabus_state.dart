import 'package:meta/meta.dart';

/// A deterministic syllabus item progression model.
/// States can be derived from existing data: completed, linked tasks, study activity.
enum SyllabusState {
  notStarted('Not Started'),
  inProgress('In Progress'),
  studied('Studied'),
  revised('Revised'),
  practiced('Practiced');

  const SyllabusState(this.label);
  final String label;
}

/// Extended syllabus item with preparation tracking.
@immutable
class SyllabusItemExtended {
  SyllabusItemExtended({
    required this.id,
    required this.title,
    this.completed = false,
    DateTime? createdAt,
    this.completedAt,
    this.state = SyllabusState.notStarted,
    this.revisionNeeded = false,
    this.practiceNeeded = false,
    this.linkedTaskIds = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;
  final SyllabusState state;
  final bool revisionNeeded;
  final bool practiceNeeded;
  final List<String> linkedTaskIds;

  SyllabusItemExtended copyWithExtended({
    bool? completed,
    DateTime? completedAt,
    SyllabusState? state,
    bool? revisionNeeded,
    bool? practiceNeeded,
    List<String>? linkedTaskIds,
    bool clearCompletedAt = false,
  }) {
    return SyllabusItemExtended(
      id: id,
      title: title,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      state: state ?? this.state,
      revisionNeeded: revisionNeeded ?? this.revisionNeeded,
      practiceNeeded: practiceNeeded ?? this.practiceNeeded,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
    );
  }
}
