import 'package:flutter/foundation.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/subject.dart';
import '../auth/auth_service.dart';
import '../notes/student_note_controller.dart';
import '../resources/resource_controller.dart';
import '../tasks/task_controller.dart';

/// Manages the student's subject list with local persistence and optional
/// Supabase cloud sync.
class SubjectController extends ChangeNotifier {
  SubjectController._();

  /// Clears in-memory state without touching persistent storage.
  void clearData() {
    _subjects.clear();
    notifyListeners();
  }

  static final SubjectController instance = SubjectController._();

  static const _subjectsKey = 'subjects';

  List<Subject> _subjects = [];
  bool _loaded = false;
  bool _disposed = false;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get isLoaded => _loaded;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  // ─── Derived queries ────────────────────────────────────────────────

  List<Subject> get activeSubjects =>
      _subjects.where((s) => s.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<Subject> get archivedSubjects =>
      _subjects.where((s) => s.archived).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Subject? subjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  int get activeCount => activeSubjects.length;
  bool get hasSubjects => _subjects.isNotEmpty;

  // ─── Loading / persistence ──────────────────────────────────────────

  Future<void> load() async {
    // Local-first: load as soon as ANY identity is known (AuthService or
    // isolation session) so cached local data never waits on the network.
    if (!AuthService.instance.isAuthenticated &&
        !AuthIsolation.instance.isAuthenticated) {
      return;
    }
    await _loadLocal();
    _loaded = true;
    if (!_disposed) notifyListeners();
    _attemptCloudLoad();
  }

  Future<void> _loadLocal() async {
    final uid = _userId;
    if (uid == null) return;
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _subjectsKey,
    );
    if (list != null) {
      _subjects = list.map((j) => Subject.fromJson(j)).toList();
    }
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      final response = await client
          .from('subjects')
          .select()
          .eq('user_id', uid)
          .order('name');
      if (response.isNotEmpty) {
        _subjects = response.map((j) => Subject.fromJson(j)).toList();
        await _saveLocal();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SubjectController] Cloud load failed: $e');
    }
  }

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _subjectsKey,
      list: _subjects.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> _attemptCloudSave() async {
    final client = SupabaseService.instance.client;
    final uid = _userId;
    if (client == null || uid == null) return;
    try {
      await client
          .from('subjects')
          .upsert(
            _subjects.map((s) => {...s.toJson(), 'user_id': uid}).toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[SubjectController] Cloud save failed: $e');
    }
  }

  /// Adds a list of catalog-instantiated [Subject]s into the student's subjects.
  ///
  /// Idempotent: If a subject linked to the same `catalogCourseId` and
  /// `catalogSubjectId` already exists, it is preserved and not duplicated.
  /// Non-destructive: Existing custom or unlinked subjects are kept intact.
  Future<List<Subject>> addCatalogSubjects(List<Subject> subjectsToAdd) async {
    final resultList = <Subject>[];
    bool hasNew = false;

    for (final candidate in subjectsToAdd) {
      final existingIndex = _subjects.indexWhere((s) =>
          s.catalogCourseId == candidate.catalogCourseId &&
          s.catalogSubjectId == candidate.catalogSubjectId);
      if (existingIndex == -1) {
        _subjects.add(candidate);
        resultList.add(candidate);
        hasNew = true;
      } else {
        // Already exists: retain existing subject to protect customizations and attached entities.
        resultList.add(_subjects[existingIndex]);
      }
    }

    if (hasNew) {
      await _saveLocal();
      if (!_disposed) notifyListeners();
      _attemptCloudSave();
    }
    return resultList;
  }

  /// Retrieves a subject by its catalog linkage.
  Subject? subjectByCatalogId(String courseId, String subjectId) {
    try {
      return _subjects.firstWhere((s) =>
          s.catalogCourseId == courseId && s.catalogSubjectId == subjectId);
    } catch (_) {
      return null;
    }
  }

  // ─── CRUD ───────────────────────────────────────────────────────────

  Future<Subject> createSubject({
    required String name,
    String shortName = '',
    String description = '',
    int? color,
    int? iconCodePoint,
  }) async {
    final subject = Subject(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      shortName: shortName.trim(),
      description: description.trim(),
      color: color,
      iconCodePoint: iconCodePoint,
    );
    _subjects.add(subject);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
    return subject;
  }

  Future<void> updateSubject(Subject updated) async {
    final index = _subjects.indexWhere((s) => s.id == updated.id);
    if (index < 0) return;
    _subjects[index] = updated;
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> setSubjectPreference(
    String subjectId,
    SubjectPreference preference,
  ) async {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index < 0) return;
    _subjects[index] = _subjects[index].copyWith(preference: preference);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> archiveSubject(String subjectId) async {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index < 0) return;
    _subjects[index] = _subjects[index].copyWith(archived: true);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> restoreSubject(String subjectId) async {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index < 0) return;
    _subjects[index] = _subjects[index].copyWith(clearArchived: true);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> deleteSubject(String subjectId) async {
    _subjects.removeWhere((s) => s.id == subjectId);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();

    // Preserve linked data: clear the reference instead of deleting anything.
    // Resources remain searchable and editable, and can be re-linked later.
    await TaskController.instance.clearSubjectReference(subjectId);
    await ResourceController.instance.clearSubjectReference(subjectId);
    await StudentNoteController.instance.clearSubjectReference(subjectId);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
