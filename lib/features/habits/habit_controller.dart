import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/habit_item.dart';
import '../auth/auth_service.dart';

/// Single source of truth for student daily/weekly habits.
///
/// Distinct from academic Tasks and Study Sessions.
/// Habit streaks are calculated strictly from recorded dates.
class HabitController extends ChangeNotifier {
  HabitController._();

  static final HabitController instance = HabitController._();

  static const String _storageKey = 'student_habits';

  List<HabitItem> _habits = [];
  bool _loaded = false;
  bool _disposed = false;
  int _counter = 0;

  List<HabitItem> get habits => List.unmodifiable(_habits);
  List<HabitItem> get activeHabits =>
      _habits.where((h) => h.isActive).toList();
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown.
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _habits.clear();
    _loaded = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      _habits.clear();
      _loaded = true;
      return;
    }

    try {
      final list = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _storageKey,
      );
      if (list != null) {
        _habits = list
            .whereType<Map<String, dynamic>>()
            .map(HabitItem.fromJson)
            .toList();
      } else {
        _habits = [];
      }
    } catch (_) {
      _habits = [];
    } finally {
      _loaded = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _storageKey,
      list: _habits.map((h) => h.toJson()).toList(),
    );
  }

  Future<HabitItem> createHabit({
    required String title,
    HabitFrequency frequency = HabitFrequency.daily,
    String iconName = 'check',
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Habit title cannot be empty');
    }

    final habit = HabitItem(
      id: 'hbt_${DateTime.now().microsecondsSinceEpoch}_${++_counter}',
      title: trimmed,
      frequency: frequency,
      iconName: iconName,
      createdAt: DateTime.now(),
    );

    _habits.add(habit);
    await _save();
    if (!_disposed) notifyListeners();
    return habit;
  }

  Future<void> toggleHabitForDate(String habitId, DateTime date) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx < 0) return;

    final habit = _habits[idx];
    final key = HabitItem.dateKey(date);
    final nextDates = Set<String>.from(habit.completedDates);

    if (nextDates.contains(key)) {
      nextDates.remove(key);
    } else {
      nextDates.add(key);
    }

    _habits[idx] = habit.copyWith(completedDates: nextDates);
    await _save();
    if (!_disposed) notifyListeners();
  }

  Future<void> toggleHabitToday(String habitId) =>
      toggleHabitForDate(habitId, DateTime.now());

  Future<void> updateHabit(HabitItem updated) async {
    final idx = _habits.indexWhere((h) => h.id == updated.id);
    if (idx < 0) return;

    _habits[idx] = updated;
    await _save();
    if (!_disposed) notifyListeners();
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    await _save();
    if (!_disposed) notifyListeners();
  }

  Future<void> toggleActive(String habitId) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx < 0) return;

    final habit = _habits[idx];
    _habits[idx] = habit.copyWith(isActive: !habit.isActive);
    await _save();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
