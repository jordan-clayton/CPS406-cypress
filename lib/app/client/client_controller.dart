import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../db/interface/db_service.dart';
import '../../db/interface/query.dart';
import '../../location/interface/location_service.dart';
import '../../login/interface/login_service.dart';
import '../../models/duplicates.dart';
import '../../models/flagged.dart';
import '../../models/report.dart';
import '../../models/subscription.dart';
import '../../models/user.dart';

class ClientController {
  DatabaseService _databaseService;
  LoginService _loginService;
  LocationService _locationService;
  User? _user;
  ValueNotifier<bool> loggedIn;

  /// Assume that the services have already been initialized before
  /// being passed to the controller
  ClientController(
      {required DatabaseService databaseService,
      required LoginService loginService,
      required LocationService locationService,
      User? user,
      bool loggedIn = false})
      : _databaseService = databaseService,
        _loginService = loginService,
        _locationService = locationService,
        _user = user,
        loggedIn = ValueNotifier(loggedIn);

  void databaseService(newService) => {_databaseService = newService};

  void loginService(newService) => {_loginService = newService};

  void locationService(newService) => {_locationService = newService};

  // TODO: it's likely wise to add close methods to all services, in case we need explicit cleanup
  // Dart doesn't have destructors :<, otherwise I'd hide this.
  void close() {
    _locationService.close();
  }

  LatLng get clientLocation => _locationService.getLocation();

  // For constant references to the user.
  // Our User object is currently mutable; this might change depending on
  // if/whether we finish a user-settings screen in time.
  UserView? get user => _user?.toView();

  /// To supply current reports to the frontend
  /// Includes unverified reports; convey this to the user in the map to encourage
  /// community moderation.
  ///  Throws on failure to retrieve data.
  ///
  ///  NOTE: in integration testing, check that stringified enumerations are
  ///  the required value type
  Future<List<Report>> getCurrentReports() async {
    try {
      log('Gathering data');
      final data =
          await _databaseService.getEntries(table: 'reports', filters: [
        DatabaseFilter(column: 'progress', operator: 'neq', value: 'closed'),
      ]);
      log('Data gathered.');
      return data.map((e) => Report.fromEntity(e)).toList(growable: false);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  // TODO: getOpenedReportsBy(Sorting Method)

  /// Updates user information: takes in a copy of the user from the frontend
  /// (ie. call copyWith to insert updated data) - handle the fcmToken as required
  /// once the implementation is done
  ///
  /// Throws on a database failure.
  Future<void> updateUser({required User user}) async {
    log('Updating user.');
    try {
      final entity = user.toEntity();
      entity['id'] = user.id;
      // This should implicitly filter based on the primary key.
      final response = await _databaseService.updateEntry(
          table: 'public.profiles', entry: entity, retrieveUpdatedRecord: true);

      if (kDebugMode) {
        assert(response['id'] == user.id, 'Failed to update user.');
      } else {
        if (response['id'] != user.id) {
          throw Exception('Failed to update user.');
        }
      }
      _user = User.fromEntity(response);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
    }
  }

  /// Subscribes a user to a report to listen for progress updates
  /// SubscriptionDTO holds all the relevant information for a subscription
  /// Since subscriptions can be anonymous, the contact method is embedded
  /// For registered users, expect this to match the user data.
  /// Throws on database failure.
  /// Subscribes anonymously if the data is incoherent.
  Future<void> subscribe({required SubscriptionDTO info}) async {
    log('Making subscription.');
    try {
      // If the user isn't authenticated/not signed up, subscribe anonymously.
      if (!loggedIn.value || null == _user) {
        return _subscribeAnonymous(anon: info);
      }

      // If the contact info is incoherent, subscribe anonymously.
      // Leave it up to the user to update their contact information in the app.
      // (feature pending).
      switch (info.notificationMethod) {
        case NotificationMethod.sms:
          if (_user!.phone != info.contact) {
            return _subscribeAnonymous(anon: info);
          }
        case NotificationMethod.email:
          if (_user!.email != info.contact) {
            return _subscribeAnonymous(anon: info);
          }
        case NotificationMethod.push:
          if (_user!.fcmToken != info.contact) {
            return _subscribeAnonymous(anon: info);
          }
      }

      final sub = Subscription(
          userID: _user!.id,
          reportID: info.reportID,
          notificationMethod: info.notificationMethod);
      await _databaseService.createEntry(
          table: 'subscriptions', entry: sub.toEntity());
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Handles anonymous subscriptions so that non-registered users can
  /// listen to progress updates.
  /// All anonymous subscriptions are treated as new users.
  /// Throws on database failure.
  /// It is up to the caller to handle the exceptions.
  Future<void> _subscribeAnonymous({required SubscriptionDTO anon}) async {
    log('Making anon subscription.');
    final anonUser = User(id: 'anonymous');
    switch (anon.notificationMethod) {
      case NotificationMethod.sms:
        anonUser.phone = anon.contact;
      case NotificationMethod.email:
        anonUser.email = anon.contact;
      case NotificationMethod.push:
        anonUser.fcmToken = anon.contact;
    }

    final data = await _databaseService.createEntry(
      table: 'public.profiles',
      entry: anonUser.toEntity(),
      retrieveNewRecord: true,
      retrieveColumns: ['id'],
    );
    if (kDebugMode) {
      assert(null != data['id'], 'Failed to create new user profile.');
    } else {
      if (null == data['id']) {
        throw Exception('Failed to create new user profile.');
      }
    }

    final String userID = data['id'];

    final sub = Subscription(
        userID: userID,
        reportID: anon.reportID,
        notificationMethod: anon.notificationMethod);
    await _databaseService.createEntry(
        table: 'subscriptions', entry: sub.toEntity());
  }

  /// For user-submitted reports.
  /// Throws on failure to submit data to the database.
  /// Throws if a user tries to report without registering/login.
  Future<void> makeReport({required Report newReport}) async {
    log('Making report.');
    if (!loggedIn.value) {
      return Future.error(Exception("User not authenticated."));
    }
    try {
      final response = await _databaseService.createEntry(
          table: 'reports',
          entry: newReport.toEntity(),
          retrieveNewRecord: true,
          retrieveColumns: ['id']);
      if (kDebugMode) {
        assert(null != response['id'], 'Failed to create report');
      } else {
        if (null == response['id']) {
          throw Exception('Failed to create report.');
        }
      }
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// For user-moderation, handles flagging of duplicate reports
  /// Throws on database failure, invalid login status.
  Future<void> reportDuplicate(
      {required int suspectedDupID, required int matchID}) async {
    log('Making duplicate.');
    if (!loggedIn.value) {
      return Future.error(Exception("User not authenticated"));
    }

    final dup = DuplicateReport(
        reportID: suspectedDupID,
        matchID: matchID,
        severity: DuplicateSeverity.suspected);
    try {
      final response = await _databaseService.createEntry(
        table: 'duplicates',
        entry: dup.toEntity(),
        retrieveNewRecord: true,
      );

      // This will throw if there is an issue with the record insertion
      if (kDebugMode) {
        assert(
            response['report_id'] == suspectedDupID &&
                response['match_id'] == matchID,
            'Failed to insert duplicate.');
      } else {
        if (response['report_id'] != suspectedDupID ||
            response['match_id'] != matchID) {
          throw Exception('Failed to insert duplicate.');
        }
      }
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// For user-moderation, handles flagging of invalid/malicious reports
  /// Throws on database failure, invalid login status.
  Future<void> flagReport(
      {required int flaggedID, required FlaggedReason reason}) async {
    log('Flagging report.');
    if (!loggedIn.value) {
      return Future.error(Exception("User not authenticated"));
    }

    final flag = Flagged(reportID: flaggedID, reason: reason);

    try {
      final response = await _databaseService.createEntry(
        table: 'flagged',
        entry: flag.toEntity(),
        retrieveNewRecord: true,
      );
      if (kDebugMode) {
        assert(
            response['report_id'] == flag.reportID &&
                FlaggedReason.fromString(response['reason']) == flag.reason,
            'Failed to create flagged entry.');
      } else {
        if (response['report_id'] != flag.reportID ||
            FlaggedReason.fromString(response['reason']) != flag.reason) {
          throw Exception('Failed to create flagged entry.');
        }
      }
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      return Future.error(e, s);
    }
  }

  /// To be called when a token is refreshed but the user has not been grabbed
  /// from the database.
  Future<void> tryRestoreUserSession() async {
    if (_loginService.hasSession) {
      await _getUserData();
    }
  }

  // TODO: if time to clean up, these should just throw if the user doesn't log in/sign up, change the interface.
  /// To authenticate users who want to read a report.
  /// Throws Exceptions on failure to retrieve user data.
  Future<bool> logIn({required String email, required String password}) async {
    log('Logging in.');
    try {
      // If there's already a session, the user has a logged-in client
      // Update the client state at the controller level to expose data to the
      // GUI.
      if (_loginService.hasSession) {
        loggedIn.value = true;

        if (null == _user || _loginService.userID != _user?.id) {
          await _getUserData();
        }
        log('Login successful');
        return true;
      }

      if (await _loginService.logIn(email: email, password: password)) {
        loggedIn.value = true;
        await _getUserData();
        log('Login successful');
        return true;
      }

      log('Login unsuccessful');
      return false;
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
      return Future.error(e, s);
    }
  }

  /// Signs up a user
  /// Throws on failure to sign up
  /// Throws on failure to create a user entry
  Future<bool> signUp(
      {required String email,
      required String password,
      String? username,
      String? phone,
      String? fcmToken}) async {
    log('Signing up.');
    try {
      final newUserID =
          await _loginService.signUp(email: email, password: password);
      // On a successful sign-up, make an entry in the public profiles table.
      if (null != newUserID) {
        _user ??= User(id: newUserID);
        _user!.email = email;
        _user!.fcmToken = fcmToken ?? _user!.fcmToken;
        _user!.username = username ?? _user!.username;
        _user!.phone = phone ?? _user!.phone;

        // TODO: fix this -> Not sure if supabase authentication requires validation before logging in/sending data.
        final userEntity = _user!.toEntity();
        // Add the newly created user ID to the record here to prevent violating FK constraints before insert.
        userEntity['id'] = _user!.id;
        await _databaseService.createEntry(
          table: 'profiles',
          entry: _user!.toEntity(),
        );
      }
      return null != newUserID;
    } on Exception catch (e, s) {
      _user = null;
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Signs out a user.
  Future<void> signOut() async {
    log('Signing out.');
    try {
      await _loginService.signOut();
      _user = null;
      loggedIn.value = false;
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Gets the user data from the public user table
  /// Throws on failure to retrieve data
  /// It is up to the caller to handle the exception
  Future<void> _getUserData() async {
    log('Getting user data.');
    final userData = await _databaseService
        .getEntry(table: 'profiles', filters: [
      DatabaseFilter(column: 'id', operator: 'eq', value: _loginService.userID)
    ]);
    log('Grabbed user data.');

    _user = User.fromEntity(userData);
  }

  void _logError(
      {required Exception exception, required StackTrace stacktrace}) {
    log("Exception: ${exception.toString()}\n StackTrace: $stacktrace");
  }
}
