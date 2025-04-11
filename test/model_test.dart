// TODO!

import 'package:cypress/app/client/client_controller.dart';
import 'package:cypress/app/common/constants.dart' as constants;
import 'package:cypress/app/common/report_utils.dart';
import 'package:cypress/app/common/utils.dart';
import 'package:cypress/app/common/validation.dart';
import 'package:cypress/db/test/test_db_service.dart';
import 'package:cypress/db/test/test_db_utils.dart';
import 'package:cypress/location/test/fallback_location_service.dart';
import 'package:cypress/login/test/test_login_service.dart';
import 'package:cypress/models/report.dart';
import 'package:cypress/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Section 1-General Functionality', () {
    test('ID_1.1 - User Registration: citizen, UNIT', () async {
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
    test('ID_1.4 - Valid login', () async {
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
      expect(
        await controller.logIn(
            email: 'testEmail@gmail.com', password: 'fakePassword'),
        true,
      );

      expect(controller.loggedIn.value, true, reason: 'Failed to log in user');
    });

    test('ID_1.5 - Invalid login', () async {
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

    test('ID_1.6 - Logout', () async {
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

  group('Section 3-Duplicates/ False Reports Heuristics Testing', () {
    test('ID_3.1 - Good match-location', () {
      // Roughly within 3 blocks or so.
      const loc1 = LatLng(43.65, -79.36);
      const loc2 = LatLng(43.65, -79.37);

      final report1 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc1.latitude,
        longitude: loc1.longitude,
      );
      final report2 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc2.latitude,
        longitude: loc2.longitude,
      );
      expect(reportCloseTo(r1: report1, r2: report2), true,
          reason:
              'Close locations returning above distance threshold\n distance: ${calculateSphericalDistance(
            lat1: report1.latitude,
            lat2: report2.latitude,
            long1: report1.longitude,
            long2: report2.longitude,
          )}\n threshold: ${constants.locationDistanceThreshold}');
    });
    test('ID_3.2 - Good match-word frequency', () {
      const desc1 =
          'A fire broke out earlier today at Union Station in Toronto, filling the busy downtown hub with smoke and causing major service disruptions. Fire crews quickly arrived to manage the situation as commuters were evacuated.';
      const desc2 =
          'Smoke filled Union Station in downtown Toronto today after a fire started inside the building. Emergency responders rushed to the scene, leading to major delays and evacuations throughout the station.';
      final score = reportWordSimilarity(desc1: desc1, desc2: desc2);
      expect(score >= 0.5, true,
          reason: 'Score did not surpass low threshold: $score');
    });
    test('ID_3.3 - Good match-location and description combined', () {
      const desc1 =
          'A fire broke out earlier today at Union Station in Toronto, filling the busy downtown hub with smoke and causing major service disruptions. Fire crews quickly arrived to manage the situation as commuters were evacuated.';
      const desc2 =
          'Smoke filled Union Station in downtown Toronto today after a fire started inside the building. Emergency responders rushed to the scene, leading to major delays and evacuations throughout the station.';
      // Roughly within 3 blocks or so.
      const loc1 = LatLng(43.65, -79.36);
      const loc2 = LatLng(43.65, -79.37);

      final report1 = Report(
          id: 0,
          category: ProblemCategory.fire,
          latitude: loc1.latitude,
          longitude: loc1.longitude,
          description: desc1);
      final report2 = Report(
        id: 0,
        category: ProblemCategory.fire,
        latitude: loc2.latitude,
        longitude: loc2.longitude,
        description: desc2,
      );

      final score = duplicateReportScore(r1: report1, r2: report2);
      expect(score >= 0.66, true,
          reason: 'Score does not reflect semantic duplicate: $score');
    });
    test('ID_3.4 - Bad match-location', () {
      const loc1 = LatLng(43.66, -79.38);

      const loc2 = LatLng(43.64, -79.43);

      final report1 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc1.latitude,
        longitude: loc1.longitude,
      );
      final report2 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc2.latitude,
        longitude: loc2.longitude,
      );
      expect(reportCloseTo(r1: report1, r2: report2), false,
          reason:
              'Far locations returning below distance threshold\n distance: ${calculateSphericalDistance(
            lat1: report1.latitude,
            lat2: report2.latitude,
            long1: report1.longitude,
            long2: report2.longitude,
          )}\n threshold: ${constants.locationDistanceThreshold}');
    });
    test('ID_3.5 - Bad match-description', () {
      const desc1 =
          'A fire broke out earlier today at Union Station in Toronto, filling the busy downtown hub with smoke and causing major service disruptions. Fire crews quickly arrived to manage the situation as commuters were evacuated.';
      const desc2 =
          'I was walking near Yonge and Gerrard tonight when I heard gunshots. People started yelling and running in all directions. Someone is lying on the ground and not moving. There’s a lot of panic. It looks serious.';

      final score = reportWordSimilarity(desc1: desc1, desc2: desc2);
      expect(score < 0.5, true,
          reason: 'Score does not reflect semantic difference: $score');
    });
    test('ID_3.6 - Bad match-location and description combined', () {
      const desc1 =
          'A fire broke out earlier today at Union Station in Toronto, filling the busy downtown hub with smoke and causing major service disruptions. Fire crews quickly arrived to manage the situation as commuters were evacuated.';
      const desc2 =
          'I was walking near Yonge and Gerrard tonight when I heard gunshots. People started yelling and running in all directions. Someone is lying on the ground and not moving. There’s a lot of panic. It looks serious.';
      const loc1 = LatLng(43.66, -79.38);
      const loc2 = LatLng(43.64, -79.43);
      const loc3 = LatLng(43.65, -79.37);

      final report1 = Report(
          id: 0,
          category: ProblemCategory.fire,
          latitude: loc1.latitude,
          longitude: loc1.longitude,
          description: desc1);
      final report2 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc2.latitude,
        longitude: loc2.longitude,
        description: desc2,
      );

      final report3 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc3.latitude,
        longitude: loc3.longitude,
        description: desc2,
      );

      final score = duplicateReportScore(r1: report1, r2: report2);
      expect(score < 0.66, true,
          reason: 'Score does not reflect semantic difference: $score');
      expect(score < 0.33, true,
          reason: 'Score does not reflect semantic difference: $score');

      // Run the test again with closer location, but still wrong.
      final closerScore = duplicateReportScore(r1: report1, r2: report3);
      expect(closerScore < 0.66, true,
          reason: 'Score does not reflect semantic difference: $closerScore');
      expect(closerScore < 0.33, true,
          reason: 'Score does not reflect semantic difference: $closerScore');
    });
    test('ID_3.7 - False report-location', () {
      const notToronto = LatLng(43.2557, -79.8711);

      expect(insideToronto(notToronto.latitude, notToronto.longitude), false,
          reason: 'Location flagged as inside toronto.');

      const closeToToronto = LatLng(43.700657, -79.513756);
      expect(insideToronto(closeToToronto.latitude, closeToToronto.longitude),
          true,
          reason: 'Location boundary is too tight');
    });
    test('ID_3.9 - Very short reports', () {
      const desc1 = 'A fire broke out on the boulevard';
      const desc2 = 'Fire at the corner';
      const desc3 = 'I was walking tonight when I heard gunshots.';
      const loc1 = LatLng(43.66, -79.38);
      const loc2 = LatLng(43.65, -79.38);

      const loc3 = LatLng(43.64, -79.43);

      final report1 = Report(
          id: 0,
          category: ProblemCategory.fire,
          latitude: loc1.latitude,
          longitude: loc1.longitude,
          description: desc1);
      final report2 = Report(
        id: 0,
        category: ProblemCategory.fire,
        latitude: loc2.latitude,
        longitude: loc2.longitude,
        description: desc2,
      );

      final report3 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc3.latitude,
        longitude: loc3.longitude,
        description: desc3,
      );

      final score = duplicateReportScore(r1: report1, r2: report2);
      // Test "The same report"
      expect(score >= 0.66, true,
          reason: 'Score does not reflect semantic difference: $score');

      // Test "Different reports"
      final closerScore = duplicateReportScore(r1: report1, r2: report3);
      expect(closerScore < 0.66, true,
          reason: 'Score does not reflect semantic difference: $closerScore');
      expect(closerScore < 0.33, true,
          reason: 'Score does not reflect semantic difference: $closerScore');
    });
    test('ID_3.10 - Reports with special characters', () {
      const desc1 = 'A fire broke out on the boulevard 🍡 👴 🌅';
      const desc2 = 'Fire at the corner 😴 💂  🐕';
      const desc3 = 'I was walking tonight when I heard gunshots. 🌍 👫 🚗';
      const loc1 = LatLng(43.66, -79.38);
      const loc2 = LatLng(43.65, -79.38);

      const loc3 = LatLng(43.64, -79.43);

      final report1 = Report(
          id: 0,
          category: ProblemCategory.fire,
          latitude: loc1.latitude,
          longitude: loc1.longitude,
          description: desc1);
      final report2 = Report(
        id: 0,
        category: ProblemCategory.fire,
        latitude: loc2.latitude,
        longitude: loc2.longitude,
        description: desc2,
      );

      final report3 = Report(
        id: 0,
        category: ProblemCategory.crime,
        latitude: loc3.latitude,
        longitude: loc3.longitude,
        description: desc3,
      );

      final score = duplicateReportScore(r1: report1, r2: report2);
      // Test "The same report"
      expect(score >= 0.66, true,
          reason: 'Score does not reflect semantic difference: $score');

      // Test "Different reports"
      final closerScore = duplicateReportScore(r1: report1, r2: report3);
      expect(closerScore < 0.66, true,
          reason: 'Score does not reflect semantic difference: $closerScore');
      expect(closerScore < 0.33, true,
          reason: 'Score does not reflect semantic difference: $closerScore');
    });
  });
  group('Section 4-Progress Updates', () {
    test('ID_4.1 - Update the status of a report-incomplete incident', () {});
    test('ID_4.2 - Update the status of a report-complete incident', () {});
    test('ID_4.4 - Verify notifications for updates on issues', () {});
    test('ID_4.5 - Flagging a fraudulent report', () {});
  });

  group('Section 5: UI testing', () {
    // This test should pass if the database returns the expected number of reports.
    test('ID_5.1 - Map functionality-view previous reported issues', () {});
    test('ID_5.4 - Validating reports-unverified reports', () {});
    test('ID_5.5 - Validating reports-unverified reports', () {});
  });
}
