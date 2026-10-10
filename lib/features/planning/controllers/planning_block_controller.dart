import 'package:flutter/foundation.dart';
import '../../../core/auth/auth_isolation.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/auth/auth_service.dart';
import '../models/planning_block.dart';

class PlanningBlockController extends ChangeNotifier {
  PlanningBlockController._();

  static final PlanningBlockController instance = PlanningBlockController._();
  static const _blocksKey = 'planning_blocks';

  List<PlanningBlock> _blocks = [];
  bool _loaded = false;

  List<PlanningBlock> get blocks => List.unmodifiable(_blocks);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _blocks.clear();
    _loaded = false;
    notifyListeners();
  }

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      // Side-effect-free: safe from initState/build; memory stays authoritative.
      _loaded = true;
      return;
    }
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _blocksKey,
    );

    if (list != null) {
      _blocks = list.map((j) => PlanningBlock.fromJson(j)).toList();
    }

    _loaded = true;
    notifyListeners();
  }

  Future<PlanningBlock> scheduleBlock(
    String? taskId,
    DateTime start,
    DateTime end, {
    String? subjectId,
    String? topicId,
    String? chapterId,
    String? examId,
    String? customTitle,
  }) async {
    if (!end.isAfter(start)) {
      throw ArgumentError('PlanningBlock: end must be after start');
    }

    final existingIndex = _blocks.indexWhere(
      (b) =>
          ((taskId != null && b.taskId == taskId) ||
           (topicId != null && b.topicId == topicId && b.taskId == null) ||
           (subjectId != null && b.subjectId == subjectId && b.taskId == null && b.topicId == null) ||
           (customTitle != null && b.customTitle == customTitle)) &&
          b.startAt == start &&
          b.endAt == end,
    );
    if (existingIndex >= 0) {
      return _blocks[existingIndex];
    }

    final block = PlanningBlock(
      id: 'pb_${DateTime.now().millisecondsSinceEpoch}_${_blocks.length + 1}',
      // Empty when identity is unknown: block stays memory-only because
      // _save() skips persistence without a resolved user.
      userId: _userId ?? '',
      taskId: taskId,
      subjectId: subjectId,
      topicId: topicId,
      chapterId: chapterId,
      examId: examId,
      customTitle: customTitle,
      startAt: start,
      endAt: end,
      createdAt: DateTime.now(),
    );

    _blocks.add(block);
    await _save();
    notifyListeners();
    return block;
  }

  Future<PlanningBlock> scheduleSubjectBlock(
    String subjectId,
    DateTime start,
    DateTime end, {
    String? customTitle,
    String? examId,
  }) {
    return scheduleBlock(
      null,
      start,
      end,
      subjectId: subjectId,
      examId: examId,
      customTitle: customTitle,
    );
  }

  Future<PlanningBlock> scheduleTopicBlock(
    String topicId,
    DateTime start,
    DateTime end, {
    String? subjectId,
    String? chapterId,
    String? examId,
    String? customTitle,
  }) {
    return scheduleBlock(
      null,
      start,
      end,
      subjectId: subjectId,
      topicId: topicId,
      chapterId: chapterId,
      examId: examId,
      customTitle: customTitle,
    );
  }

  Future<PlanningBlock?> rescheduleBlock(
    String blockId,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    if (!newEnd.isAfter(newStart)) {
      throw ArgumentError('PlanningBlock: newEnd must be after newStart');
    }

    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index < 0) return null;

    final updated = _blocks[index].copyWith(
      startAt: newStart,
      endAt: newEnd,
      updatedAt: DateTime.now(),
    );

    _blocks[index] = updated;
    await _save();
    notifyListeners();
    return updated;
  }

  Future<void> unscheduleBlock(String blockId) async {
    _blocks.removeWhere((b) => b.id == blockId);
    await _save();
    notifyListeners();
  }

  Future<void> unscheduleTask(String taskId) async {
    _blocks.removeWhere((b) => b.taskId == taskId);
    await _save();
    notifyListeners();
  }

  Future<void> unscheduleSubject(String subjectId) async {
    _blocks.removeWhere((b) => b.subjectId == subjectId && b.taskId == null);
    await _save();
    notifyListeners();
  }

  List<PlanningBlock> blocksForTask(String taskId) {
    return _blocks.where((b) => b.taskId == taskId).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  List<PlanningBlock> blocksForSubject(String subjectId) {
    return _blocks.where((b) => b.subjectId == subjectId).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  List<PlanningBlock> blocksForDay(DateTime day) {
    return _blocks.where((b) {
      return b.startAt.year == day.year &&
          b.startAt.month == day.month &&
          b.startAt.day == day.day;
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  PlanningBlock? blockForTaskOnDay(String taskId, DateTime day) {
    return _blocks.where((b) {
      return b.taskId == taskId &&
          b.startAt.year == day.year &&
          b.startAt.month == day.month &&
          b.startAt.day == day.day;
    }).firstOrNull;
  }

  PlanningBlock? blockForSubjectOnDay(String subjectId, DateTime day) {
    return _blocks.where((b) {
      return b.subjectId == subjectId &&
          b.taskId == null &&
          b.startAt.year == day.year &&
          b.startAt.month == day.month &&
          b.startAt.day == day.day;
    }).firstOrNull;
  }

  int totalScheduledMinutesForDay(DateTime day) {
    final dayBlocks = blocksForDay(day);
    int minutes = 0;
    for (final b in dayBlocks) {
      minutes += b.endAt.difference(b.startAt).inMinutes;
    }
    return minutes;
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _blocksKey,
      list: _blocks.map((b) => b.toJson()).toList(),
    );
  }
}
