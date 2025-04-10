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
// import '../../models/subscription.dart';
import '../../models/employee.dart';

class EmployeeController {
  DatabaseService _databaseService;
  LoginService _loginService;
  LocationService _locationService;
  Employee? _employee;
  ValueNotifier<bool> loggedIn;

  /// Assume that the services have already been initialized before
  /// being passed to the controller
  EmployeeController(
      {required DatabaseService databaseService,
      required LoginService loginService,
      required LocationService locationService,
      Employee? employee,
      bool loggedIn = false})
      : _databaseService = databaseService,
        _loginService = loginService,
        _locationService = locationService,
        _employee = employee,
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
  void addLocationListener(
      {required String owner,
      required void Function(bool) onPermissionChanged}) {
    _locationService.addLocationListener(
        owner: owner, onPermissionChanged: onPermissionChanged);
  }

  void removeLocationListener({required String owner}) {
    _locationService.removeLocationListener(owner: owner);
  }

  // For constant references to the user.
  // Our User object is currently mutable; this might change depending on
  // if/whether we finish a user-settings screen in time.
  EmployeeView? get employee => _employee?.toView();

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
  Future<void> updateEmployee({required Employee employee}) async {
    log('Updating employee.');
    try {
      final entity = employee.toEntity();
      entity['id'] = employee.uuid;
      // This should implicitly filter based on the primary key.
      final response = await _databaseService.updateEntry(
          table: 'public.employees', entry: entity, retrieveUpdatedRecord: true);

      if (kDebugMode) {
        assert(response['id'] == employee.uuid, 'Failed to update employee.');
      } else {
        if (response['id'] != employee.uuid) {
          throw Exception('Failed to update employee.');
        }
      }
      _employee = Employee.fromEntity(entity: response);
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
  
  /// Handles anonymous subscriptions so that non-registered users can
  /// listen to progress updates.
  /// All anonymous subscriptions are treated as new users.
  /// Throws on database failure.
  /// It is up to the caller to handle the exceptions.
  

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
  Future<bool> logIn({required String employeeID, required String password}) async {
    log('Logging in.');
    try {
      // If there's already a session, the user has a logged-in client
      // Update the client state at the controller level to expose data to the
      // GUI.
      if (_loginService.hasSession) {
        loggedIn.value = true;

        if (null == _employee || _loginService.userID != _employee?.uuid) {
          await _getUserData();
        }
        log('Login successful');
        return true;
      }

      if (await _loginService.logIn(email: employeeID, password: password)) {
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

  /// Signs up an employee
  /// Throws on failure to sign up
  /// Throws on failure to create a user entry
  Future<bool> signUp(
      {required String employeeID,
      required String password,
      String? firstName,
      String? lastName,
      String? authLevel}) async {
    log('Signing up.');
    try {
      final newEmployeeUID =
          await _loginService.signUp(email: employeeID, password: password);
          //since its just a string im reusing the existing function name
          
          
      // On a successful sign-up, make an entry in the public profiles table.
      if (null != newEmployeeUID) {
        _employee ??= Employee(uuid: newEmployeeUID, employeeID: _employee!.employeeID);
        // employee has a uuid but also employee id?
        
        _employee!.firstName = firstName ?? _employee!.firstName;
        _employee!.lastName = lastName ?? _employee!.lastName;
        _employee!.auth = Authority.fromString(authLevel!);

        // TODO: fix this -> Not sure if supabase authentication requires validation before logging in/sending data.
        final employeeEntity = _employee!.toEntity();
        // Add the newly created user ID to the record here to prevent violating FK constraints before insert.
        employeeEntity['uuid'] = _employee!.uuid;
        await _databaseService.createEntry(
          table: 'employees',
          entry: _employee!.toEntity(),
        );
      }
      return null != newEmployeeUID;
    } on Exception catch (e, s) {
      _employee = null;
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Signs out a user.
  Future<void> signOut() async {
    log('Signing out.');
    try {
      await _loginService.signOut();
      _employee = null;
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
    final employeeData = await _databaseService
        .getEntry(table: 'employees', filters: [
      DatabaseFilter(column: 'id', operator: 'eq', value: _loginService.userID)
    ]);
    log('Grabbed user data.');

    _employee = Employee.fromEntity(entity: employeeData);
  }

  void _logError(
      {required Exception exception, required StackTrace stacktrace}) {
    log("Exception: ${exception.toString()}\n StackTrace: $stacktrace");
  }
}
