/// Overall application authentication view-state, used by the auth gate to
/// determine which screen to display.
///
/// The decision tree is:
///
/// ```
/// Supabase ready?
///   ├─ no  → demoMode
///   └─ yes → sessionState
///              ├─ checking  → loading
///              ├─ unauthenticated → unauthenticated
///              └─ authenticated   → authenticated
/// ```
///
/// Separated from Supabase init state to make the distinction clear:
/// "Supabase not configured" ≠ "User is logged out".
enum AuthViewState {
  /// Supabase is not configured or initialization failed; the app is in
  /// local/demo mode and no authentication is required or shown.
  demoMode,

  /// Supabase is ready and we are checking/restoring the session.
  checking,

  /// Supabase is ready and the user is not authenticated.
  unauthenticated,

  /// Supabase is ready and the user is authenticated.
  authenticated,

  passwordRecovery,
}

/// Current state of the Supabase auth session.
enum SessionState {
  /// Checking for an existing session (startup / restore).
  checking,

  /// No active session.
  unauthenticated,

  /// Active session available.
  authenticated,
}

/// Human-readable reason for a failed authentication operation.
///
/// Designed for the UI layer — short, safe, and user-friendly.
/// Never exposes tokens, keys, or internal Supabase error dumps.
enum AuthError {
  invalidEmail('Please enter a valid email address.'),

  weakPassword('Password must be at least 6 characters.'),

  passwordsMismatch('Passwords do not match.'),

  invalidCredentials('Incorrect email or password. Please try again.'),

  emailAlreadyInUse('An account already exists with this email address.'),

  emailNotConfirmed('Please verify your email before signing in.'),

  userNotFound('No account found with this email address.'),

  tooManyRequests('Too many attempts. Please try again in a few minutes.'),

  network('Network issue. Check your connection and try again.'),

  googleConfig('Google Sign-In configuration issue. Please check client setup.'),

  unknown('Something went wrong. Please try again.');

  const AuthError(this.message);
  final String message;
}
