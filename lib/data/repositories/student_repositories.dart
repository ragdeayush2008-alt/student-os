import '../../core/auth/auth_isolation.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../data/models/task.dart';
import '../../features/auth/auth_service.dart';

/// Generic repository contract providing local-first reads and mutations with cloud synchronization.
abstract class BaseRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> save(T item);
  Future<void> delete(String id);
  Future<void> syncWithCloud();
}

/// Specialized repository for Task entity.
class TaskRepository implements BaseRepository<StudentTask> {
  TaskRepository._();
  static final TaskRepository instance = TaskRepository._();

  static const _tasksKey = 'tasks';
  static const _tableName = 'tasks';

  String? get _userId =>
      AuthIsolation.resolveUserId(AuthService.instance.user?.id);

  @override
  Future<List<StudentTask>> getAll() async {
    final uid = _userId;
    if (uid == null) return [];
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _tasksKey,
    );
    if (list == null) return [];
    return list.map((json) => StudentTask.fromJson(json)).toList();
  }

  @override
  Future<StudentTask?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(StudentTask item) async {
    final uid = _userId;
    if (uid == null) return;
    final all = await getAll();
    final idx = all.indexWhere((t) => t.id == item.id);
    if (idx >= 0) {
      all[idx] = item;
    } else {
      all.add(item);
    }

    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _tasksKey,
      list: all.map((t) => t.toJson()).toList(),
    );

    // Queue for cloud sync
    await SyncQueue.instance.enqueue(
      table: _tableName,
      recordId: item.id,
      type: SyncOperationType.upsert,
      payload: item.toJson(),
    );

    // Attempt direct sync if online
    SyncEngine.instance.synchronize();
  }

  @override
  Future<void> delete(String id) async {
    final uid = _userId;
    if (uid == null) return;
    final all = await getAll();
    all.removeWhere((t) => t.id == id);

    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _tasksKey,
      list: all.map((t) => t.toJson()).toList(),
    );

    // Queue delete for cloud sync
    await SyncQueue.instance.enqueue(
      table: _tableName,
      recordId: id,
      type: SyncOperationType.delete,
      payload: {'id': id},
    );

    SyncEngine.instance.synchronize();
  }

  @override
  Future<void> syncWithCloud() async {
    final client = SupabaseService.instance.client;
    final user = AuthService.instance.user;
    if (client == null || user == null) return;

    try {
      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', user.id);

      final cloudTasks = (response as List)
          .map((json) => StudentTask.fromJson(json as Map<String, dynamic>))
          .toList();

      final localTasks = await getAll();
      final mergedMap = <String, StudentTask>{};

      for (final t in localTasks) {
        mergedMap[t.id] = t;
      }

      for (final ct in cloudTasks) {
        if (!mergedMap.containsKey(ct.id)) {
          mergedMap[ct.id] = ct;
        } else {
          // Last write wins based on updatedAt / createdAt
          final local = mergedMap[ct.id]!;
          if (ct.createdAt.isAfter(local.createdAt)) {
            mergedMap[ct.id] = ct;
          }
        }
      }

      final uid = _userId;
      if (uid == null) return;
      await StorageService.instance.saveJsonList(
        userId: uid,
        key: _tasksKey,
        list: mergedMap.values.map((t) => t.toJson()).toList(),
      );
    } catch (_) {}
  }
}
