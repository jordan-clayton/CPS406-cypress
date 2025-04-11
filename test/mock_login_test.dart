import 'package:flutter_test/flutter_test.dart';
import '../lib/login/test/test_login_service.dart';

void main() {
  group('MockLoginService', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUserID = 'fake-user-id';

    test('Successful login with correct credentials', () async {
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: testEmail,
        fakeClientPassword: testPassword,
        fakeUserID: testUserID,
      );

      final result = await loginService.logIn(email: testEmail, password: testPassword);
      expect(result, isTrue);
      expect(loginService.hasSession, isTrue);
      expect(loginService.userID, equals(testUserID));
    });

    test('Login fails with incorrect email', () async {
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: testEmail,
        fakeClientPassword: testPassword,
        fakeUserID: testUserID,
      );

      final result = await loginService.logIn(email: 'wrong@example.com', password: testPassword);
      expect(result, isFalse);
      expect(loginService.hasSession, isFalse);
    });

    test('Login fails with incorrect password', () async {
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: testEmail,
        fakeClientPassword: testPassword,
        fakeUserID: testUserID,
      );

      final result = await loginService.logIn(email: testEmail, password: 'wrongpass');
      expect(result, isFalse);
      expect(loginService.hasSession, isFalse);
    });

    test('Throws exception when trying to login twice', () async {
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: testEmail,
        fakeClientPassword: testPassword,
        fakeUserID: testUserID,
      );

      await loginService.logIn(email: testEmail, password: testPassword);

      expect(
        () async => await loginService.logIn(email: testEmail, password: testPassword),
        throwsException,
      );
    });

    test('Sign out resets session', () async {
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: testEmail,
        fakeClientPassword: testPassword,
        fakeUserID: testUserID,
      );

      await loginService.logIn(email: testEmail, password: testPassword);
      await loginService.signOut();
      expect(loginService.hasSession, isFalse);
    });
  });
}
