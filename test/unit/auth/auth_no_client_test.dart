import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/supabase_service.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_state.dart';

/// Regression: auth must never fail silently when Supabase is unreachable.
///
/// Previously `SupabaseService.initialize()` was never called from `main()`,
/// so `client` was always null and every sign-in (email AND Google) failed
/// with a generic [AuthError.unknown]. These tests pin:
/// 1. A null client surfaces [AuthError.network] (actionable message).
/// 2. Web `fetch` failures classify as network errors.
void main() {
  setUp(() async {
    SupabaseService.instance.resetForTesting();
    await SupabaseService.instance.initialize(url: '', anonKey: '');
    expect(SupabaseService.instance.client, isNull);
  });

  group('null Supabase client', () {
    test('email sign-in returns network error, not unknown', () async {
      final result = await AuthService.instance.signIn(
        email: 'a@b.com',
        password: 'password123',
      );
      expect(result.isFailure, isTrue);
      expect(result.error, AuthError.network);
    });

    test('sign-up returns network error, not unknown', () async {
      final result = await AuthService.instance.signUp(
        email: 'a@b.com',
        password: 'password123',
      );
      expect(result.isFailure, isTrue);
      expect(result.error, AuthError.network);
    });

    test('google sign-in returns network error, not unknown', () async {
      final result = await AuthService.instance.signInWithGoogle();
      expect(result.isFailure, isTrue);
      expect(result.error, AuthError.network);
    });
  });

  group('classifyAuthError web failures', () {
    test('failed fetch maps to network', () {
      expect(
        classifyAuthError(Exception('ClientException: Failed to fetch')),
        AuthError.network,
      );
    });
  });
}
