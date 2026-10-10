import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/auth/auth_state.dart';

void main() {
  group('AuthValidator unit tests', () {
    test('validates standard email', () {
      expect(AuthValidator.isValidEmail('test@example.com'), isTrue);
      expect(AuthValidator.isValidEmail('invalid'), isFalse);
      expect(AuthValidator.isValidEmail(''), isFalse);
    });

    test('validates password strength', () {
      expect(AuthValidator.isStrongPassword('123456'), isTrue);
      expect(AuthValidator.isStrongPassword('12345'), isFalse);
    });
  });

  group('classifyAuthError mapping', () {
    test('maps invalid login credentials', () {
      expect(classifyAuthError('Invalid login credentials'), AuthError.invalidCredentials);
    });

    test('maps network errors', () {
      expect(classifyAuthError('SocketException: failed to connect'), AuthError.network);
    });

    test('maps Google developer error 10 / sign_in_failed', () {
      expect(classifyAuthError('PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)'), AuthError.googleConfig);
    });
  });

  group('AuthResult cancelled handling', () {
    test('cancelled result has no error and is marked as not success', () {
      const result = AuthResult.cancelled();
      expect(result.isSuccess, isFalse);
      expect(result.error, isNull);
    });
  });
}
