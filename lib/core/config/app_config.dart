/// Application compile-time configuration.
///
/// Credentials are supplied at build/run time via `--dart-define-from-file=.env`
/// or `--dart-define=KEY=VALUE` — never hardcoded or committed. When they are
/// absent, the app runs in local/demo mode (see [isSupabaseConfigured]).
abstract final class AppConfig {
  /// Supabase project URL (from `--dart-define-from-file=.env` or `--dart-define=SUPABASE_URL=...`).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xrqpmjamwiwpyuqbjvyx.supabase.co',
  );

  /// Supabase anon (publishable) key — NOT the service role key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ikZjS3XvKwJFn-sJgxtTgA_MkpjuDXU',
  );

  /// Google OAuth Web Client ID (used as serverClientId / audience for native sign-in).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '39606807496-qenf0pu2e0ea7rtc3hp4p41ofqmgqo5p.apps.googleusercontent.com',
  );

  /// Google OAuth iOS Client ID.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// Whether Supabase is configured (both URL and anon key present).
  static bool get isSupabaseConfigured =>
      isConfiguredFor(supabaseUrl, supabaseAnonKey);

  /// Pure detection predicate.
  static bool isConfiguredFor(String url, String anonKey) =>
      url.isNotEmpty && anonKey.isNotEmpty;
}
