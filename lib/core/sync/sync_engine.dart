import 'dart:async';

import 'package:uuid/uuid.dart';

import '../auth/auth_isolation.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../../features/auth/auth_service.dart';

import 'package:flutter/foundation.dart';

/// The operation type queued for synchronization.
enum SyncOperationType {
  upsert('upsert'),
  delete('delete');

  const SyncOperationType(this.value);
  final String value;

  static SyncOperationType fromString(String val) {
    return SyncOperationType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => SyncOperationType.upsert,
    );
  }
}

/// A pending mutation waiting to sync to the remote Supabase cloud.
class SyncMutation {
  const SyncMutation({
    required this.id,
    required this.table,
    required this.recordId,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final String table;
  final String recordId;
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int retryCount;
  final String? lastError;

  SyncMutation copyWith({int? retryCount, String? lastError}) {
    return SyncMutation(
      id: id,
      table: table,
      recordId: recordId,
      type: type,
      payload: payload,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'recordId': recordId,
    'type': type.value,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
    'lastError': lastError,
  };

  factory SyncMutation.fromJson(Map<String, dynamic> json) {
    return SyncMutation(
      id: json['id'] as String,
      table: json['table'] as String,
      recordId: json['recordId'] as String,
      type: SyncOperationType.fromString(json['type'] as String),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: (json['retryCount'] as int?) ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}

/// Current state of the Sync Engine.
enum SyncState {
  idle('Idle'),
  syncing('Syncing'),
  offline('Offline'),
  error('Sync Error');

  const SyncState(this.label);
  final String label;
}

/// Persistent offline sync queue and background coordinator.
///
/// Ensures all local-first actions are queued and reliably flushed to Supabase
/// when network connectivity is available.
class SyncQueue extends ChangeNotifier {
  SyncQueue._();
  static final SyncQueue instance = SyncQueue._();

  static const _queueKey = 'sync_mutation_queue';
  static final _uuid = const Uuid();

  List<SyncMutation> _queue = [];

  List<SyncMutation> get queue => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get hasPending => _queue.isNotEmpty;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId => AuthIsolation.resolveUserId(
        AuthService.instance.user?.id,
      );

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      _queue = [];
      notifyListeners();
      return;
    }
    final list = await StorageService.instance.loadJsonList(
      userId: uid,
      key: _queueKey,
    );
    if (list != null) {
      _queue = list.map(SyncMutation.fromJson).toList();
    } else {
      _queue = [];
    }
    notifyListeners();
  }

  Future<void> enqueue({
    required String table,
    required String recordId,
    required SyncOperationType type,
    required Map<String, dynamic> payload,
  }) async {
    // If an earlier mutation for this same record is queued, collapse or update it
    _queue.removeWhere((m) => m.table == table && m.recordId == recordId);

    final mutation = SyncMutation(
      id: _uuid.v4(),
      table: table,
      recordId: recordId,
      type: type,
      payload: payload,
      timestamp: DateTime.now(),
    );

    _queue.add(mutation);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String mutationId) async {
    _queue.removeWhere((m) => m.id == mutationId);
    await _persist();
    notifyListeners();
  }

  Future<void> recordFailure(String mutationId, String error) async {
    final idx = _queue.indexWhere((m) => m.id == mutationId);
    if (idx != -1) {
      final current = _queue[idx];
      _queue[idx] = current.copyWith(
        retryCount: current.retryCount + 1,
        lastError: error,
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _queue.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJsonList(
      userId: uid,
      key: _queueKey,
      list: _queue.map((m) => m.toJson()).toList(),
    );
  }
}

/// Central Sync Engine managing two-way synchronization between Local Cache and Supabase Cloud.
class SyncEngine extends ChangeNotifier {
  SyncEngine._();
  static final SyncEngine instance = SyncEngine._();

  SyncState _state = SyncState.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  bool _isSyncing = false;

  SyncState get state => _state;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isSyncing => _isSyncing;

  /// Trigger a full sync cycle: flush local mutations + fetch cloud updates.
  Future<bool> synchronize() async {
    if (_isSyncing) return false;
    final client = SupabaseService.instance.client;
    final user = AuthService.instance.user;

    if (client == null || user == null) {
      _state = SyncState.offline;
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _state = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Process pending offline mutations
      final queue = SyncQueue.instance;
      final pending = List<SyncMutation>.from(queue.queue);

      for (final mutation in pending) {
        try {
          if (mutation.type == SyncOperationType.upsert) {
            final payloadWithUser = Map<String, dynamic>.from(mutation.payload);
            payloadWithUser['user_id'] = user.id; // Enforce user isolation
            if (mutation.table == 'student_profiles') {
              payloadWithUser['id'] = user.id;
            }
            await client.from(mutation.table).upsert(payloadWithUser);
          } else if (mutation.type == SyncOperationType.delete) {
            // Security: always enforce user isolation on delete
            await client
                .from(mutation.table)
                .delete()
                .eq('id', mutation.recordId)
                .eq('user_id', user.id);
          }
          await queue.remove(mutation.id);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[SyncEngine] Mutation ${mutation.id} failed: $e');
          }
          await queue.recordFailure(mutation.id, e.toString());
        }
      }

      _lastSyncTime = DateTime.now();
      _state = SyncState.idle;
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[SyncEngine] Full sync failed: $e');
      _lastError = e.toString();
      _state = SyncState.error;
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
}
