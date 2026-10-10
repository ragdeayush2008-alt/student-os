import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/notification_coordinator.dart';
import '../../core/services/storage_service.dart';
import '../../core/time/app_clock.dart';
import '../../core/utils/app_week_utils.dart';
import '../auth/auth_service.dart';
import '../calendar/academic_schedule_controller.dart';
import '../planning/controllers/planning_block_controller.dart';
import 'models/daily_life_plan.dart';
import 'models/sleep_record.dart';
import 'models/sleep_summary.dart';
import 'models/student_life_preferences.dart';
import 'services/student_life_engine.dart';

class StudentLifeController extends ChangeNotifier {
  StudentLifeController._();

  static final StudentLifeController instance = StudentLifeController._();

  static const String _prefsKey = 'student_life_preferences';
  static const String _sleepKey = 'student_life_sleep_records';
  static const String _completionKey = 'student_life_routine_completion';

  StudentLifePreferences _preferences = const StudentLifePreferences();
  List<SleepRecord> _sleepRecords = [];
  final Map<String, Set<String>> _completion = {};
  bool _loaded = false;
  bool _disposed = false;
  int _counter = 0;
  int _revision = 0;
  bool _listening = false;

  StudentLifePreferences get preferences => _preferences;
  List<SleepRecord> get sleepRecords => List.unmodifiable(_sleepRecords);
  bool get isLoaded => _loaded;
  int get revision => _revision;

  String? get _userId => AuthIsolation.resolveUserId(
    AuthService.instance.user?.id,
  );

  void init() {
    if (_listening) return;
    _listening = true;
    PlanningBlockController.instance.addListener(_onSourceChanged);
    AcademicScheduleController.instance.addListener(_onSourceChanged);
  }

  void _onSourceChanged() {
    _revision++;
    if (!_disposed) notifyListeners();
  }

  void clearData() {
    _preferences = const StudentLifePreferences();
    _sleepRecords = [];
    _completion.clear();
    _loaded = false;
    _revision++;
    if (!_disposed) notifyListeners();
    unawaited(NotificationCoordinator.instance.cancelStudentLifeNotifications());
  }

  Future<void> load() async {
    init();
    final uid = _userId;
    if (uid == null) {
      _preferences = const StudentLifePreferences();
      _sleepRecords = [];
      _completion.clear();
      _loaded = true;
      if (!_disposed) notifyListeners();
      await NotificationCoordinator.instance.cancelStudentLifeNotifications();
      return;
    }

    try {
      final prefsJson = await StorageService.instance.loadJson(
        userId: uid,
        key: _prefsKey,
      );
      _preferences = prefsJson == null
          ? const StudentLifePreferences()
          : StudentLifePreferences.fromJson(prefsJson);

      final sleep = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _sleepKey,
      );
      _sleepRecords = sleep == null
          ? []
          : sleep.map(SleepRecord.fromJson).toList();

      final completion = await StorageService.instance.loadJson(
        userId: uid,
        key: _completionKey,
      );
      _completion.clear();
      if (completion != null) {
        completion.forEach((key, value) {
          if (value is List) {
            _completion[key] = value.whereType<String>().toSet();
          }
        });
      }
    } catch (_) {
      _preferences = const StudentLifePreferences();
      _sleepRecords = [];
      _completion.clear();
    } finally {
      _loaded = true;
      _revision++;
      if (!_disposed) notifyListeners();
      await NotificationCoordinator.instance.reconcileStudentLifeNotifications(
        preferences: _preferences,
      );
    }
  }

  Future<void> _savePreferences() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _prefsKey,
      json: _preferences.toJson(),
    );
  }

  Future<void> _saveSleep() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _sleepKey,
      list: _sleepRecords.map((r) => r.toJson()).toList(),
    );
  }

  Future<void> _saveCompletion() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _completionKey,
      json: _completion.map((key, value) => MapEntry(key, value.toList())),
    );
  }

  Future<void> updatePreferences(StudentLifePreferences preferences) async {
    _preferences = preferences;
    await _savePreferences();
    if (!_disposed) notifyListeners();
    await NotificationCoordinator.instance.reconcileStudentLifeNotifications(
      preferences: preferences,
    );
  }

  Future<SleepRecord> logSleep({
    required DateTime bedtime,
    required DateTime wakeTime,
    int? quality,
    String note = '',
  }) async {
    final safeWake = wakeTime.isAfter(bedtime)
        ? wakeTime
        : bedtime.add(const Duration(minutes: 1));
    final record = SleepRecord(
      id: 'sleep_${AppClock.current.microsecondsSinceEpoch}_${++_counter}',
      bedtime: bedtime,
      wakeTime: safeWake,
      quality: quality,
      note: note,
      source: SleepRecordSource.manual,
      createdAt: AppClock.current,
    );
    _sleepRecords.add(record);
    await _saveSleep();
    if (!_disposed) notifyListeners();
    return record;
  }

  Future<SleepRecord?> logNap({
    required DateTime start,
    required int minutes,
    String note = '',
  }) async {
    if (minutes <= 0) return null;
    final record = SleepRecord(
      id: 'nap_${AppClock.current.microsecondsSinceEpoch}_${++_counter}',
      bedtime: start,
      wakeTime: start.add(Duration(minutes: minutes)),
      type: SleepEntryType.nap,
      note: note,
      source: SleepRecordSource.manual,
      createdAt: AppClock.current,
    );
    _sleepRecords.add(record);
    await _saveSleep();
    if (!_disposed) notifyListeners();
    return record;
  }

  Future<void> deleteSleepRecord(String id) async {
    _sleepRecords.removeWhere((r) => r.id == id);
    await _saveSleep();
    if (!_disposed) notifyListeners();
  }

  bool isRoutineItemDone(DateTime day, String itemId) =>
      _completion[_dayKey(day)]?.contains(itemId) ?? false;

  Future<void> toggleRoutineItemDone(DateTime day, String itemId) async {
    final key = _dayKey(day);
    final set = _completion.putIfAbsent(key, () => <String>{});
    if (!set.remove(itemId)) set.add(itemId);
    if (set.isEmpty) _completion.remove(key);
    await _saveCompletion();
    if (!_disposed) notifyListeners();
  }

  DailyLifePlan dailyPlan([DateTime? day]) {
    final target = AppWeekUtils.dateOnly(day ?? AppClock.current);
    final plan = StudentLifeEngine.buildDailyPlan(
      day: target,
      preferences: _preferences,
      sleepRecords: _sleepRecords,
      calendarEvents: AcademicScheduleController.instance.eventsForDay(target),
      referenceTime: AppClock.current,
    );
    final completion = _completion[_dayKey(target)];
    if (completion == null || completion.isEmpty) return plan;
    return DailyLifePlan(
      day: plan.day,
      sleepWindowStart: plan.sleepWindowStart,
      sleepWindowEnd: plan.sleepWindowEnd,
      targetSleepMinutes: plan.targetSleepMinutes,
      items: plan.items
          .map((i) => i.copyWith(isCompleted: completion.contains(i.id)))
          .toList(),
      studyTargetMinutes: plan.studyTargetMinutes,
      scheduledStudyMinutes: plan.scheduledStudyMinutes,
      generatedAt: plan.generatedAt,
      latestStudyEnd: plan.latestStudyEnd,
      warnings: plan.warnings,
      reducedOptionalCount: plan.reducedOptionalCount,
      fixedCommitmentCount: plan.fixedCommitmentCount,
      fixedCommitmentTitles: plan.fixedCommitmentTitles,
      droppedEssentialCount: plan.droppedEssentialCount,
    );
  }

  SleepSummary sleepSummary() => StudentLifeEngine.summarize(
    _sleepRecords,
    referenceTime: AppClock.current,
    targetBedtimeMinutes: _preferences.targetBedtimeMinutes,
  );

  String? get lastNightBedtimeLabel {
    final summary = sleepSummary();
    final t = summary.lastNightBedtime;
    if (t == null) return null;
    return StudentLifePreferences.formatClock(t.hour * 60 + t.minute);
  }

  static String _dayKey(DateTime day) =>
      '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _disposed = true;
    if (_listening) {
      PlanningBlockController.instance.removeListener(_onSourceChanged);
      AcademicScheduleController.instance.removeListener(_onSourceChanged);
      _listening = false;
    }
    super.dispose();
  }
}
