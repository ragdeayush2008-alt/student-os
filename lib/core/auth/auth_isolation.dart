/// Central user session isolation manager.
///
/// NOT a data store — only manages in-memory isolation state and
/// broadcasts session changes so controllers can reload.
class AuthIsolation {
  AuthIsolation._();
  static final AuthIsolation instance = AuthIsolation._();

  String? _currentUserId;
  bool _isAuthenticated = false;

  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _isAuthenticated;
  bool get hasSessionChanged =>
      (_currentUserId != null && !_isAuthenticated) ||
      (_currentUserId == null && _isAuthenticated);

  /// Call on login/session change with NEW user ID.
  void setAuthenticatedUser(String userId) {
    if (_currentUserId == userId && _isAuthenticated) return;
    _currentUserId = userId;
    _isAuthenticated = true;
  }

  /// Call on logout — does NOT delete persistent storage.
  void clearSession() {
    _currentUserId = null;
    _isAuthenticated = false;
  }

  /// Verify new user is different from previous.
  bool isDifferentUser(String userId) =>
      userId != _currentUserId || !_isAuthenticated;

  /// Single source of truth for user-scoped identity resolution.
  ///
  /// Prefers the isolation session (set on every login, including restored
  /// sessions) and falls back to the [AuthService] user id. Returns `null`
  /// when no identity is known (logged out / unknown).
  ///
  /// Callers MUST treat `null` as memory-only: never persist under a shared
  /// fallback namespace (no `'demo'` user) so data can never leak across
  /// users on the same device.
  static String? resolveUserId(String? authServiceUserId) =>
      instance.currentUserId ?? authServiceUserId;
}
