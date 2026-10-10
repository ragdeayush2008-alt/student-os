import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

import 'package:flutter/foundation.dart';

/// Lifecycle state of the Supabase connection foundation.
enum SupabaseInitState {
  /// Credentials were not supplied; the app runs in local/demo mode.
  notConfigured,

  /// Credentials were found and initialization is in progress.
  initializing,

  /// Initialization succeeded; a client is available.
  ready,

  /// Credentials were supplied but initialization failed.
  failed,
}

/// Bootstraps the Supabase client for the whole app.
///
/// Responsibilities:
/// - Reads configuration from [AppConfig] (never hardcoded credentials).
/// - Initializes Supabase **only** when valid credentials are configured.
/// - Prevents accidental double/repeated initialization.
/// - Exposes the current state via [state] (a [ValueListenable] so future UI
///   or diagnostics can observe it) and a safe [client] accessor that is only
///   non-null when ready.
///
/// Initialization is intentionally non-blocking and fire-and-forget; when
/// Supabase is unconfigured or fails, the app continues in local/demo mode and
/// never crashes because of it.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  final ValueNotifier<SupabaseInitState> _state = ValueNotifier(
    SupabaseInitState.notConfigured,
  );

  SupabaseClient? _client;
  bool _attempted = false;
  String? _lastErrorDescription;
  Completer<void> _initCompleter = Completer<void>();

  /// Observable initialization state.
  ValueListenable<SupabaseInitState> get state => _state;

  /// Current initialization state (non-observing convenience read).
  SupabaseInitState get currentState => _state.value;

  /// The initialized client, or `null` unless the service is [ready].
  ///
  /// Future features should obtain the client through this accessor and guard
  /// on readiness rather than calling Supabase globals directly.
  SupabaseClient? get client => _client;

  /// A short, non-sensitive description of the last failure (null if none).
  /// Useful for developer diagnostics; never contains anon keys.
  String? get lastErrorDescription => _lastErrorDescription;

  /// Waits for initialization attempt to finish (up to [timeout]).
  Future<void> ensureInitialized({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_state.value != SupabaseInitState.initializing && _attempted) {
      return;
    }
    try {
      await _initCompleter.future.timeout(timeout);
    } catch (_) {
      // Handled gracefully
    }
  }

  /// Initializes Supabase.
  ///
  /// - Not configured  → state becomes [notConfigured], returns immediately.
  /// - Configured      → attempts init; succeeds (ready) or fails (failed).
  Future<void> initialize({String? url, String? anonKey}) async {
    if (_attempted) return;
    _attempted = true;

    final effectiveUrl = url ?? AppConfig.supabaseUrl;
    final effectiveKey = anonKey ?? AppConfig.supabaseAnonKey;

    if (!AppConfig.isConfiguredFor(effectiveUrl, effectiveKey)) {
      _state.value = SupabaseInitState.notConfigured;
      _log('Supabase not configured — running in local/demo mode.');
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      return;
    }

    _state.value = SupabaseInitState.initializing;
    try {
      // Explicitly configure PKCE flow and deep-link detection for mobile.
      final supabase = await Supabase.initialize(
        url: effectiveUrl,
        publishableKey: effectiveKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          detectSessionInUri: true,
        ),
        debug: kDebugMode,
      );
      _client = supabase.client;
      _state.value = SupabaseInitState.ready;
      _log(
        'Supabase initialized. url=$effectiveUrl pkce=true detectSessionInUri=true',
      );
      // Log auth state changes for diagnostics (especially OAuth deep-link return).
      _client!.auth.onAuthStateChange.listen(
        (data) {
          if (kDebugMode) {
            debugPrint(
              '[SupabaseService] onAuthStateChange event=${data.event} session=${data.session != null} user=${data.session?.user.email}',
            );
          }
        },
        onError: (e, st) {
          if (kDebugMode) {
            debugPrint('[SupabaseService] onAuthStateChange error: $e');
          }
        },
      );
    } catch (error) {
      _client = null;
      _state.value = SupabaseInitState.failed;
      _lastErrorDescription = _describe(error);
      _log('Supabase initialization failed: $_lastErrorDescription');
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  /// Reset state for testing.
  @visibleForTesting
  void resetForTesting() {
    _attempted = false;
    _client = null;
    _lastErrorDescription = null;
    _initCompleter = Completer<void>();
    _state.value = SupabaseInitState.notConfigured;
  }

  /// Creates a short, developer-facing description of a failure without
  /// exposing credentials (anon keys are never included by Supabase init
  /// exceptions, and we use the type + message only).
  String _describe(Object error) {
    final trimmed = error.toString().trim();
    return trimmed.length > 400 ? '${trimmed.substring(0, 400)}…' : trimmed;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SupabaseService] $message');
    }
  }

  /// Releases resources. Intended for tests only.
  @visibleForTesting
  void dispose() {
    _state.dispose();
  }
}
