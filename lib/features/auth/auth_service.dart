import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_isolation.dart';
import '../../core/auth/controller_isolation.dart';
import '../../core/config/app_config.dart';
import '../../core/services/supabase_service.dart';
import 'auth_state.dart';

import 'package:flutter/foundation.dart';

/// Pure, testable email/password validation helpers.
///
/// Kept separate from [AuthService] so that validation logic can be tested
/// deterministically without any Supabase dependency.
abstract final class AuthValidator {
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  static bool isStrongPassword(String password) => password.length >= 6;

  static bool passwordsMatch(String a, String b) => a == b;
}

/// Maps a Supabase [AuthException] to a user-friendly [AuthError].
///
/// Intentionally conservative — we never expose raw exception messages to
/// the user, but we preserve diagnostic information in debug logs.
AuthError classifyAuthError(Object error) {
  final String message;
  if (error is AuthException) {
    message = error.message.toLowerCase();
  } else {
    message = error.toString().toLowerCase();
  }

  if (kDebugMode) debugPrint('[AuthService] Error: $message');

  if (message.contains('invalid login credentials') ||
      message.contains('invalid grant')) {
    return AuthError.invalidCredentials;
  }
  if (message.contains('already registered') ||
      message.contains('already been registered') ||
      message.contains('user already registered') ||
      message.contains('email address has already been registered')) {
    return AuthError.emailAlreadyInUse;
  }
  if (message.contains('email') &&
      (message.contains('invalid') || message.contains('format'))) {
    return AuthError.invalidEmail;
  }
  if (message.contains('email not confirmed') ||
      message.contains('email address not confirmed')) {
    return AuthError.emailNotConfirmed;
  }
  if (message.contains('user not found') || message.contains('no user found')) {
    return AuthError.userNotFound;
  }
  if (message.contains('password') &&
      (message.contains('at least') || message.contains('minimum'))) {
    return AuthError.weakPassword;
  }
  if (message.contains('rate limit') || message.contains('too many')) {
    return AuthError.tooManyRequests;
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('failed to fetch') ||
      message.contains('fetch failed') ||
      message.contains('clientexception')) {
    return AuthError.network;
  }
  if (message.contains('10') ||
      message.contains('developer_error') ||
      message.contains('sign_in_failed') ||
      message.contains('googleconfig')) {
    return AuthError.googleConfig;
  }

  return AuthError.unknown;
}

/// Manages authentication state and provides auth operations.
///
/// Initializes Supabase listening first, then resolves the session state
/// before any user-scoped data is loaded. When Supabase is not configured,
/// the view-state is [demoMode] and no private data is shown. Otherwise it
/// follows the session state.
///
/// Auth operations (sign in, sign up, etc.) are exposed as async methods that
/// return [AuthResult] — a lightweight, testable result type that avoids
/// scattering `try/catch` throughout the UI layer.
class AuthService extends ChangeNotifier {
  AuthService._() {
    _initSupabaseListener();
  }

  static final AuthService instance = AuthService._();

  StreamSubscription<AuthState>? _authSubscription;
  AuthViewState _viewState = AuthViewState.demoMode;
  SessionState _sessionState = SessionState.checking;
  User? _user;
  bool _disposed = false;

  /// Completes when the initial auth session has been restored or
  /// when Supabase is unavailable/failed — guarantees terminal state.
  final Completer<void> _initComplete = Completer<void>();

  /// Future that resolves once the initial authentication state
  /// is fully resolved (either session restored or unavailable).
  Future<void> get initializationComplete => _initComplete.future;

  /// Current view-state driving the auth gate.
  AuthViewState get viewState => _viewState;

  /// Current session state (meaningful only when Supabase is ready).
  SessionState get sessionState => _sessionState;

  /// Current authenticated user (null when not authenticated).
  User? get user => _user;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _sessionState == SessionState.authenticated;

  // ─── Supabase init listener ────────────────────────────────────────────

  void _initSupabaseListener() {
    // Follow the Supabase init state.
    SupabaseService.instance.state.addListener(_onSupabaseStateChanged);
    // Set initial state.
    _onSupabaseStateChanged();
  }

  void _onSupabaseStateChanged() {
    final supaState = SupabaseService.instance.currentState;

    switch (supaState) {
      case SupabaseInitState.notConfigured:
      case SupabaseInitState.failed:
        _user = null;
        _updateSessionState(SessionState.unauthenticated);
        _updateViewState(AuthViewState.demoMode);
        if (!_initComplete.isCompleted) _initComplete.complete();
        return;
      case SupabaseInitState.initializing:
        _user = null;
        _updateSessionState(SessionState.checking);
        _updateViewState(AuthViewState.checking);
        return;
      case SupabaseInitState.ready:
        _listenToAuthChanges();
        _restoreSession();
        return;
    }
  }

  // ─── Auth state listening ──────────────────────────────────────────────

  void _listenToAuthChanges() {
    if (_authSubscription != null) return;
    final client = SupabaseService.instance.client;
    if (client == null) return;

    _authSubscription = client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final prevUser = _user;
      _user = session?.user;

      if (kDebugMode) {
        debugPrint('[AuthService] onAuthStateChange event=${data.event}');
      }

      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (kDebugMode) {
          debugPrint('[AuthService] PASSWORD_RECOVERY event received');
        }
        _updateSessionState(SessionState.authenticated);
        _updateViewState(AuthViewState.passwordRecovery);
        return;
      }

      if (session != null && _user != null) {
        final newId = _user!.id;
        if (prevUser == null || prevUser.id != newId) {
          AuthIsolation.instance.setAuthenticatedUser(newId);
          ControllerIsolation.instance.reloadAllControllers(newId);
        }
        _updateSessionState(SessionState.authenticated);
        _updateViewState(AuthViewState.authenticated);
      } else {
        if (prevUser != null && _user == null) {
          AuthIsolation.instance.clearSession();
          ControllerIsolation.instance.clearAllControllers();
        }
        _updateSessionState(SessionState.unauthenticated);
        _updateViewState(AuthViewState.unauthenticated);
        _user = null;
      }
    });
  }

  // ─── Session restore ──────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    _updateViewState(AuthViewState.checking);
    _updateSessionState(SessionState.checking);

    try {
      final session = client.auth.currentSession;
      _user = session?.user;
      if (session != null && _user != null) {
        AuthIsolation.instance.setAuthenticatedUser(_user!.id);
        ControllerIsolation.instance.reloadAllControllers(_user!.id);
        _updateSessionState(SessionState.authenticated);
        _updateViewState(AuthViewState.authenticated);
      } else {
        _user = null;
        AuthIsolation.instance.clearSession();
        _updateSessionState(SessionState.unauthenticated);
        _updateViewState(AuthViewState.unauthenticated);
      }
      if (!_initComplete.isCompleted) _initComplete.complete();
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] Session restore failed: $e');
      _user = null;
      _updateSessionState(SessionState.unauthenticated);
      _updateViewState(AuthViewState.unauthenticated);
      if (!_initComplete.isCompleted) _initComplete.complete();
    }
  }

  // ─── Auth operations ──────────────────────────────────────────────────

  /// Signs in with email/password via Supabase Auth.
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signIn: Supabase client is null '
          '(state=${SupabaseService.instance.currentState}, '
          'isConfigured=${AppConfig.isSupabaseConfigured})',
        );
      }
      return const AuthResult.failure(AuthError.network);
    }

    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      // Session listener will update auth state.
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    } catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    }
  }

  /// Signs up with email/password via Supabase Auth.
  ///
  /// After success, Supabase may require email confirmation. If a session is
  /// returned the user is authenticated; if not, email confirmation is pending.
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signUp: Supabase client is null '
          '(state=${SupabaseService.instance.currentState})',
        );
      }
      return const AuthResult.failure(AuthError.network);
    }

    try {
      final redirectUrl = kIsWeb ? null : authRedirectUri;
      if (kDebugMode) {
        debugPrint('[AuthService] signUp emailRedirectTo=$redirectUrl');
      }
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: redirectUrl,
      );
      final session = response.session;
      if (session != null) {
        return const AuthResult.success();
      }
      return const AuthResult.emailConfirmationPending();
    } on AuthException catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    } catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    }
  }

  /// Sends a password reset email via Supabase Auth.
  Future<AuthResult> resetPassword({required String email}) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      return const AuthResult.failure(AuthError.network);
    }

    try {
      final redirectUrl = kIsWeb ? null : authRedirectUri;
      if (kDebugMode) {
        debugPrint('[AuthService] resetPassword redirectTo=$redirectUrl');
      }
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectUrl,
      );
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    } catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    }
  }

  Future<AuthResult> updatePassword({required String newPassword}) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      return const AuthResult.failure(AuthError.network);
    }

    try {
      if (kDebugMode) {
        debugPrint('[AuthService] Updating user password');
      }
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    } catch (e) {
      return AuthResult.failure(classifyAuthError(e));
    }
  }

  static const String authRedirectUri =
      'com.ragdetechnologies.studentos://login-callback/';

  static const String androidOAuthRedirect = authRedirectUri;

  /// Legacy underscore scheme — kept for inbound deep-link handling only.
  static const String androidOAuthRedirectLegacy =
      'com.ragdetechnologies.student_os://login-callback/';

  /// Signs in with Google OAuth via Supabase.
  ///
  /// Uses the VALID scheme `com.ragdetechnologies.studentos://login-callback/`
  /// (no underscore) for the `redirectTo`. The legacy
  /// `com.ragdetechnologies.student_os` (underscore) is kept for inbound
  /// handling but is NOT used for OAuth because Go's `url.Parse` rejects it
  /// ("first path segment in URL cannot contain colon" → `IsRedirectURLValid`
  /// false → `GetReferrer` falls back to Site URL `http://localhost:3000`).
  /// Dart `Uri.tryParse` also returns null for underscore, so `app_links`'s
  /// `uriLinkStream` drops it. The localhost `http` filter is a safety net for
  /// the fallback case, but the primary fix is the valid scheme.
  /// Signs in with native Google Sign-In and exchanges ID/access tokens with Supabase.
  ///
  /// No browser or external redirect is opened. Uses native Google Account chooser.
  Future<AuthResult> signInWithGoogle() async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] Native Google Sign-In: Supabase client is null '
          '(state=${SupabaseService.instance.currentState}, '
          'isConfigured: ${AppConfig.isSupabaseConfigured})',
        );
      }
      return const AuthResult.failure(AuthError.network);
    }

    try {
      if (kDebugMode) {
        debugPrint('[AuthService] Starting native Google Sign-In flow');
      }

      // On web the plugin needs the WEB client ID as `clientId` (it falls
      // back to the google-signin-client_id meta tag when null). On mobile,
      // `clientId` is the iOS client ID (null → Info.plist fallback) and
      // `serverClientId` is the web client ID used as the token audience.
      final webClientId = AppConfig.googleWebClientId.isNotEmpty
          ? AppConfig.googleWebClientId
          : null;
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? webClientId
            : (AppConfig.googleIosClientId.isNotEmpty
                  ? AppConfig.googleIosClientId
                  : null),
        serverClientId: webClientId,
        scopes: const ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) debugPrint('[AuthService] User cancelled Google Sign-In');
        return const AuthResult.cancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        if (kDebugMode) {
          debugPrint(
            '[AuthService] Google Sign-In failed: missing ID token. '
            'Ensure GOOGLE_WEB_CLIENT_ID is supplied via --dart-define or .env',
          );
        }
        return const AuthResult.failure(AuthError.googleConfig);
      }

      if (kDebugMode) {
        debugPrint('[AuthService] Exchanging Google tokens with Supabase');
      }

      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        _user = response.user;
        AuthIsolation.instance.setAuthenticatedUser(response.user!.id);
        _updateSessionState(SessionState.authenticated);
        _updateViewState(AuthViewState.authenticated);
        return const AuthResult.success();
      }

      return const AuthResult.failure(AuthError.unknown);
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Google Sign-In Supabase AuthException: ${e.message}');
      }
      return AuthResult.failure(classifyAuthError(e));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Google Sign-In Exception: $e');
      }
      return AuthResult.failure(classifyAuthError(e));
    }
  }

  /// Signs out and resets auth state.
  Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        if (kDebugMode) debugPrint('[AuthService] Sign out error: $e');
      }
    }
    _user = null;
    AuthIsolation.instance.clearSession();
    ControllerIsolation.instance.clearAllControllers();
    _updateSessionState(SessionState.unauthenticated);
    _updateViewState(AuthViewState.unauthenticated);
    notifyListeners();
  }

  // ─── State updates ────────────────────────────────────────────────────

  void _updateViewState(AuthViewState newState) {
    if (_viewState == newState) return;
    _viewState = newState;
    if (!_disposed) notifyListeners();
  }

  void _updateSessionState(SessionState newState) {
    if (_sessionState == newState) return;
    _sessionState = newState;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    SupabaseService.instance.state.removeListener(_onSupabaseStateChanged);
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Lightweight result type for auth operations.
///
/// Avoids throwing exceptions to the UI and keeps error handling explicit.
@immutable
class AuthResult {
  const AuthResult.success()
    : isSuccess = true,
      isEmailConfirmationPending = false,
      error = null;

  const AuthResult.emailConfirmationPending()
    : isSuccess = false,
      isEmailConfirmationPending = true,
      error = null;

  const AuthResult.cancelled()
    : isSuccess = false,
      isEmailConfirmationPending = false,
      error = null;

  const AuthResult.failure(this.error)
    : isSuccess = false,
      isEmailConfirmationPending = false;

  final bool isSuccess;
  final bool isEmailConfirmationPending;
  final AuthError? error;

  bool get isFailure => !isSuccess && !isEmailConfirmationPending;
}
