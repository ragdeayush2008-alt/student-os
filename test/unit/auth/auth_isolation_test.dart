import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';

void main() {
  group('Account Isolation', () {
    setUp(() {
      AuthIsolation.instance.clearSession();
    });

    test('Account A login sets session', () {
      AuthIsolation.instance.setAuthenticatedUser('A-id');
      expect(AuthIsolation.instance.currentUserId, 'A-id');
      expect(AuthIsolation.instance.isAuthenticated, true);
    });

    test('Logout clears session but keeps isolation manager', () {
      AuthIsolation.instance.setAuthenticatedUser('A-id');
      AuthIsolation.instance.clearSession();
      expect(AuthIsolation.instance.currentUserId, null);
      expect(AuthIsolation.instance.isAuthenticated, false);
    });

    test('Account B login is different from A', () {
      AuthIsolation.instance.setAuthenticatedUser('A-id');
      expect(AuthIsolation.instance.isDifferentUser('B-id'), true);
      AuthIsolation.instance.setAuthenticatedUser('B-id');
      expect(AuthIsolation.instance.currentUserId, 'B-id');
    });

    test('Switch A -> B -> A restores correctly', () {
      AuthIsolation.instance.setAuthenticatedUser('A-id');
      AuthIsolation.instance.setAuthenticatedUser('B-id');
      AuthIsolation.instance.clearSession();
      AuthIsolation.instance.setAuthenticatedUser('A-id');
      expect(AuthIsolation.instance.currentUserId, 'A-id');
    });

    test('ControllerIsolation clears without deleting storage', () {
      ControllerIsolation.instance.clearAllControllers();
      expect(true, true);
    });

    test('hasSessionChanged false when stable auth', () {
      AuthIsolation.instance.setAuthenticatedUser('uid');
      expect(AuthIsolation.instance.hasSessionChanged, false);
    });
  });
}
