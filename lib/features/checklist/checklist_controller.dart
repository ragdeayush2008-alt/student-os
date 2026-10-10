import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/checklist_item.dart';
import '../auth/auth_service.dart';

/// Single source of truth for lightweight student checklist items.
///
/// Completely independent from [TaskController] (does not award Task XP,
/// does not affect task completion metrics). Persisted offline-first and user-scoped.
class ChecklistController extends ChangeNotifier {
  ChecklistController._();

  static final ChecklistController instance = ChecklistController._();

  static const String _storageKey = 'student_checklist';

  List<ChecklistItem> _items = [];
  bool _loaded = false;
  bool _disposed = false;
  int _counter = 0;

  List<ChecklistItem> get items => List.unmodifiable(_items);
  List<ChecklistItem> get pendingItems =>
      _items.where((i) => !i.isCompleted).toList();
  List<ChecklistItem> get completedItems =>
      _items.where((i) => i.isCompleted).toList();
  bool get isLoaded => _loaded;
  int get pendingCount => pendingItems.length;

  /// Resolved user id, or `null` when unknown.
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  void clearData() {
    _items.clear();
    _loaded = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      _items.clear();
      _loaded = true;
      return;
    }

    try {
      final list = await StorageService.instance.loadJsonList(
        userId: uid,
        key: _storageKey,
      );
      if (list != null) {
        _items = list
            .whereType<Map<String, dynamic>>()
            .map(ChecklistItem.fromJson)
            .toList();
      } else {
        _items = [];
      }
    } catch (_) {
      _items = [];
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
      list: _items.map((i) => i.toJson()).toList(),
    );
  }

  Future<ChecklistItem> addItem(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Checklist item title cannot be empty');
    }

    final item = ChecklistItem(
      id: 'chk_${DateTime.now().microsecondsSinceEpoch}_${++_counter}',
      title: trimmed,
      createdAt: DateTime.now(),
    );

    _items.insert(0, item);
    await _save();
    if (!_disposed) notifyListeners();
    return item;
  }

  Future<void> toggleItem(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;

    final item = _items[idx];
    final nextStatus = !item.isCompleted;
    _items[idx] = item.copyWith(
      isCompleted: nextStatus,
      completedAt: nextStatus ? DateTime.now() : null,
      clearCompletedAt: !nextStatus,
    );

    await _save();
    if (!_disposed) notifyListeners();
  }

  Future<void> editItem(String id, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;

    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;

    _items[idx] = _items[idx].copyWith(title: trimmed);
    await _save();
    if (!_disposed) notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _save();
    if (!_disposed) notifyListeners();
  }

  Future<void> clearCompleted() async {
    _items.removeWhere((i) => i.isCompleted);
    await _save();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
