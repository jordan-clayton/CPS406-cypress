// TODO!

import 'package:cypress/app/client/client_controller.dart';
import 'package:cypress/db/test/test_db_service.dart';
import 'package:cypress/db/test/test_db_utils.dart';
import 'package:cypress/location/test/fallback_location_service.dart';
import 'package:cypress/login/test/test_login_service.dart';
import 'package:cypress/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Group tests like so.
  group('Section 1', () {
    test('ID: 1.1 - User Registration: citizen, UNIT', () async {
      // Set up the database
      final dbService = MockDatabaseService(seedData: seedEmptyDatabase());
      final loginService = MockLoginService();
      final locationService = FallbackLocationService();

      final controller = ClientController(
          databaseService: dbService,
          loginService: loginService,
          locationService: locationService);

      // NOTE: if this fails, it might indicate an issue with the test
      // This has been shown to work in (manual) integration testing.
      expect(
          await controller.signUp(
              email: 'testEmail@gmail.com', password: 'fakePassword'),
          true,
          reason: 'Failed to sign up user');
    });

    /// Test individual test cases related to a particular group here
    test('ID: 1.4 - Valid login', () async {
      // Mock user
      final seedUser = User(id: '', email: 'testEmail@gmail.com');

      // Set up database
      final db = seedDatabaseWithProfiles(userProfiles: [seedUser]);
      // Get the user id.
      final userID = db['profiles']!.first['id'];

      final dbService = MockDatabaseService(seedData: db);

      // Set up login service
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: seedUser.email!,
        fakeClientPassword: 'fakePassword',
        fakeUserID: userID,
      );

      // Set up location service
      final locationService = FallbackLocationService();

      // Set up controller.
      final controller = ClientController(
          databaseService: dbService,
          loginService: loginService,
          locationService: locationService);

      // Simulate valid login.
      // NOTE: if this fails, there's a bug with the mock.
      // The (manual) integration testing indicates this works..
      expect(
        await controller.logIn(
            email: 'testEmail@gmail.com', password: 'fakePassword'),
        true,
      );

      expect(controller.loggedIn.value, true, reason: 'Failed to log in user');
    });

    test('ID: 1.5 - Invalid login', () async {
      // Mock user
      final seedUser = User(id: '', email: 'testEmail@gmail.com');

      // Set up database
      final db = seedDatabaseWithProfiles(userProfiles: [seedUser]);
      // Get the user id.
      final userID = db['profiles']!.first['id'];

      final dbService = MockDatabaseService(seedData: db);

      // Set up login service
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: seedUser.email!,
        fakeClientPassword: 'fakePassword',
        fakeUserID: userID,
      );

      // Set up location service
      final locationService = FallbackLocationService();

      // Set up controller.
      final controller = ClientController(
          databaseService: dbService,
          loginService: loginService,
          locationService: locationService);

      // Simulate invalid login.
      // NOTE: if this fails, there's a bug with the mock.
      // The (manual) integration testing indicates this works..
      expect(
          await controller.logIn(
              email: 'testEmail@gmail.com', password: 'wrongPassword'),
          false,
          reason: 'Wrong password still logged in');
      expect(
          await controller.logIn(
              email: 'wrongEmail@gmail.com', password: 'fakePassword'),
          false,
          reason: 'Wrong email still logged in');
      expect(controller.loggedIn.value, false,
          reason: 'Client logged in with invalid credentials.');
    });

    test('ID: 1.6 - Logout', () async {
      // Mock user
      final seedUser = User(id: '', email: 'testEmail@gmail.com');

      // Set up database
      final db = seedDatabaseWithProfiles(userProfiles: [seedUser]);
      // Get the user id.
      final userID = db['profiles']!.first['id'];

      final dbService = MockDatabaseService(seedData: db);

      // Set up login service
      final loginService = MockLoginService.withMockedCredentials(
        fakeClientEmail: seedUser.email!,
        fakeClientPassword: 'fakePassword',
        fakeUserID: userID,
      );

      // Set up location service
      final locationService = FallbackLocationService();

      // Set up controller.
      final controller = ClientController(
          databaseService: dbService,
          loginService: loginService,
          locationService: locationService);

      // Simulate valid login.
      // NOTE: if this fails, there's a bug with the mock.
      // The (manual) integration testing indicates this works..
      expect(
        await controller.logIn(
            email: 'testEmail@gmail.com', password: 'fakePassword'),
        true,
      );

      expect(controller.loggedIn.value, true,
          reason: 'Client failed to log in.');

      // Sign out.
      await controller.signOut();
      expect(controller.loggedIn.value, false,
          reason:
              'Client failed to log out, or state is not updated in controller.');
    });
  });
}
