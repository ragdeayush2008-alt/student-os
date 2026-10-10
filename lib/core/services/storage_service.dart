import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Handles all local persistence via [SharedPreferences].
///
/// Data is user-scoped: keys are prefixed with the resolved user id so
/// different accounts never share local data on the same device.
/// There is intentionally no shared fallback namespace: callers must resolve
/// identity via `AuthIsolation.resolveUserId` and stay memory-only when it
/// is unknown (logged out).
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Scoped key helpers ──────────────────────────────────────────────

  String _key(String userId, String suffix) => 'uos_${userId}_$suffix';

  // ─── String persistence ──────────────────────────────────────────────

  Future<void> saveString({
    required String userId,
    required String key,
    required String value,
  }) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_key(userId, key), value);
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] saveString error: $e');
    }
  }

  Future<String?> loadString({
    required String userId,
    required String key,
  }) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_key(userId, key));
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] loadString error: $e');
      return null;
    }
  }

  // ─── JSON object persistence ────────────────────────────────────────

  Future<void> saveJson({
    required String userId,
    required String key,
    required Map<String, dynamic> json,
  }) async {
    await saveString(userId: userId, key: key, value: jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadJson({
    required String userId,
    required String key,
  }) async {
    final raw = await loadString(userId: userId, key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] loadJson parse error: $e');
      return null;
    }
  }

  // ─── List persistence ───────────────────────────────────────────────

  Future<void> saveJsonList({
    required String userId,
    required String key,
    required List<Map<String, dynamic>> list,
  }) async {
    await saveString(userId: userId, key: key, value: jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>?> loadJsonList({
    required String userId,
    required String key,
  }) async {
    final raw = await loadString(userId: userId, key: key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] loadJsonList parse error: $e');
      return null;
    }
  }

  // ─── Boolean persistence ────────────────────────────────────────────

  Future<void> saveBool({
    required String userId,
    required String key,
    required bool value,
  }) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_key(userId, key), value);
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] saveBool error: $e');
    }
  }

  Future<bool> loadBool({
    required String userId,
    required String key,
    bool defaultValue = false,
  }) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_key(userId, key)) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // ─── Integer persistence ────────────────────────────────────────────

  Future<void> saveInt({
    required String userId,
    required String key,
    required int value,
  }) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_key(userId, key), value);
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] saveInt error: $e');
    }
  }

  Future<int?> loadInt({required String userId, required String key}) async {
    try {
      final prefs = await _getPrefs();
      return prefs.getInt(_key(userId, key));
    } catch (e) {
      return null;
    }
  }

  // ─── Cleanup ────────────────────────────────────────────────────────

  Future<void> remove({required String userId, required String key}) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_key(userId, key));
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] remove error: $e');
    }
  }

  Future<void> clearUser({required String userId}) async {
    try {
      final prefs = await _getPrefs();
      final prefix = 'uos_${userId}_';
      final keys = prefs.getKeys().where((k) => k.startsWith(prefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Storage] clearUser error: $e');
    }
  }
}
