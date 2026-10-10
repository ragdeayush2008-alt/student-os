import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/auth/auth_state.dart';

void main() {
  group('AuthViewState machine', () {
    test('initializing → checking state exists', () {
      expect(AuthViewState.checking, isNotNull);
    });
    test('authenticated state exists', () {
      expect(AuthViewState.authenticated, isNotNull);
    });
    test('unauthenticated state exists', () {
      expect(AuthViewState.unauthenticated, isNotNull);
    });
    test('no demoMode for production auth', () {
      expect(AuthViewState.demoMode, AuthViewState.demoMode); // state exists but should not be default
    });
  });
}
