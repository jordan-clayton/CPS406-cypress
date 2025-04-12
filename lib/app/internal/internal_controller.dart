import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../db/interface/db_service.dart';
import '../../db/interface/query.dart';
import '../../login/interface/login_service.dart';
import '../../models/duplicates.dart';
import '../../models/employee.dart';
import '../../models/flagged.dart';
import '../../models/report.dart';
import '../../notification/interface/notification_service.dart';
import '../common/report_utils.dart' as report_utils;

class InternalController {
  DatabaseService _databaseService;
  NotificationService _notificationService;
  LoginService _loginService;
  Employee? _employee;
  ValueNotifier<bool> loggedIn;

  InternalController(
      {required DatabaseService databaseService,
      required LoginService loginService,
      required NotificationService notificationService,
      Employee? employee,
      bool loggedIn = false})
      : _databaseService = databaseService,
        _notificationService = notificationService,
        _loginService = loginService,
        _employee = employee,
        loggedIn = ValueNotifier(loggedIn);

  void databaseService(newService) => {_databaseService = newService};
  void notificationService(newService) => {_notificationService = newService};
  void loginService(newService) => {_loginService = newService};

  /// Retrieves a list of records containing (flaggedReport, reasonForFlagging)
  /// These will need to be unpacked in the frontend accordingly
  /// Throws on an invalid database retrieval
  Future<List<(Report, FlaggedReason)>> getFlagged() async {
    try {
      final data = await _databaseService.getEntries(
          table: 'flagged',
          columns: ['report_id:reports!flagged_report_id_fkey(*)', 'reason']);
      return data
          .map((e) => (
                Report.fromEntity(e['report_id']),
                FlaggedReason.fromString(e['reason'])
              ))
          .toList(growable: false);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Retrieves a list of record containing: (suspectedReport, matchingReport, Likelihood)
  /// These will need to be unpacked in the frontend accordingly
  /// Throws on an invalid database retrieval.
  Future<List<(Report, Report, DuplicateSeverity)>> getDuplicates() async {
    try {
      final data =
          await _databaseService.getEntries(table: 'duplicates', columns: [
        'report_id:reports!duplicates_report_id_fkey(*)',
        'match_id:reports!duplicates_match_id_fkey(*)',
        'severity'
      ]);
      return data
          .map((e) => (
                Report.fromEntity(e['report_id']),
                Report.fromEntity(e['match_id']),
                DuplicateSeverity.fromString(e['severity'])
              ))
          .toList(growable: false);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  Future<void> updateReport({required Report report}) async {
    final entity = report.toEntity();
    // Add the primary key to the mapping.
    // Assume the database knows how to handle it.
    entity['id'] = report.id;
    try {
      final response = await _databaseService.updateEntry(
          table: 'reports',
          entry: entity,
          retrieveUpdatedRecord: true,
          retrieveColumns: ['id']);

      if (kDebugMode) {
        assert(response['id']! == report.id, 'Failed to update user.');
      } else {
        if (response['id'] != report.id) {
          throw Exception('Failed to update user.');
        }
      }
      // Update users.
      _notifySubscribers(report: report);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Update the duplicates table with new severity.
  /// Intended use is for manual verification.
  /// Confirmed duplicates are automatically closed.
  ///
  /// Throws exceptions on invalid database results.
  Future<void> updateDuplicate(
      {required int reportID, required DuplicateSeverity severity}) async {
    try {
      final response = await _databaseService.updateEntry(
          table: 'duplicates',
          // Add the ID to the entry so that the DB service can locate the record.
          entry: {'id': reportID, 'severity': severity.name},
          retrieveUpdatedRecord: true,
          retrieveColumns: ['report_id']);

      // Assert is for debug mode only.
      if (kDebugMode) {
        assert(
            response['report_id']! == reportID, 'failure to update duplicate');
      } else {
        if (response['report_id'] != reportID) {
          throw Exception('Failure to update duplicate');
        }
      }

      // If it's a confirmed duplicate, close the report automatically
      if (severity == DuplicateSeverity.confirmed) {
        final response = await _databaseService.updateEntry(
          table: 'reports',
          entry: {'id': reportID, 'progress': ProgressStatus.closed.name},
          retrieveUpdatedRecord: true,
        );

        if (kDebugMode) {
          assert(response['id']! == reportID, 'Failed to close report');
        } else {
          if (response['id'] != reportID) {
            throw Exception('Failed to close report.');
          }
        }

        // Update subscribers
        _notifySubscribers(report: Report.fromEntity(response));
      }
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Retrieves a list of currently unverified records so that an employee can
  /// manually verify or close.
  /// Throws on an invalid database retrieval
  Future<List<Report>> getUnverified() async {
    try {
      final data = await _databaseService.getEntries(
          table: 'reports',
          filters: [
            DatabaseFilter(column: 'verified', operator: 'eq', value: false)
          ]);
      return data.map((e) => Report.fromEntity(e)).toList(growable: false);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Returns a Bisected list of reports separated by opened and in-progress status
  /// This should be handled accordingly in the frontend: (ie. two expandable lists)
  /// Intended use: manually updating progress.
  /// Throws on an invalid database retrieval.
  Future<Map<String, List<Report>>> getVerifiedOpenedReports() async {
    try {
      final data = await _getVerifiedOpenedData();

      final groupedData = groupBy(data, (e) => e['progress']);
      return {
        'in-progress': (groupedData['in-progress'] ?? [])
            .map((e) => Report.fromEntity(e))
            .toList(growable: false),
        'opened': (groupedData['opened'] ?? [])
            .map((e) => Report.fromEntity(e))
            .toList(growable: false)
      };
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Helper method for grabbing unverified/non-duplicate report data
  /// Performs a left-join on the duplicates table to filter out already
  /// suspected duplicates.
  Future<List<Map<String, dynamic>>> _getUnverifiedNonDuplicates() async {
    return await _databaseService.getEntries(table: 'reports', columns: [
      '*',
      'duplicates(report_id, severity)'
    ], filters: [
      DatabaseFilter(
          column: 'duplicates.severity',
          operator: 'neq',
          value: DuplicateSeverity.unlikely.name),
      DatabaseFilter(
          column: 'duplicates.severity',
          operator: 'neq',
          value: DuplicateSeverity.confirmed.name),
      DatabaseFilter(
          column: 'duplicates.report_id', operator: 'is', value: null)
    ]);
  }

  /// Helper method for grabbing verified/open report data
  Future<List<Map<String, dynamic>>> _getVerifiedOpenedData() async {
    return await _databaseService.getEntries(table: 'reports', filters: [
      DatabaseFilter(column: 'progress', operator: 'neq', value: 'closed'),
      DatabaseFilter(column: 'verified', operator: 'eq', value: true)
    ]);
  }

  /// This runs a pass over all unverified reports and checks whether a new
  /// report is possibly a duplicate.
  ///
  /// Throws on invalid database retrieval (or some other unchecked Exception).
  /// Throws on an invalid duplicate score
  Future<void> checkForSuspectedDuplicates() async {
    try {
      final unverifiedData = await _getUnverifiedNonDuplicates();
      final unverified = unverifiedData
          .map((e) => Report.fromEntity(e))
          .toList(growable: false);

      final verifiedData = await _getVerifiedOpenedData();
      final verifiedOpen =
          verifiedData.map((e) => Report.fromEntity(e)).toList(growable: false);

      List<Map<String, dynamic>> duplicates = List.empty(growable: true);
      for (var u in unverified) {
        for (var v in verifiedOpen) {
          final duplicateSeverity = _measureDuplicate(r1: u, r2: v);
          if (duplicateSeverity != DuplicateSeverity.unlikely) {
            final dup = DuplicateReport(
                reportID: u.id, matchID: v.id, severity: duplicateSeverity);
            duplicates.add(dup.toEntity());
          }
        }
      }

      if (duplicates.isNotEmpty) {
        final checkList = await _databaseService.createEntries(
            table: 'duplicates',
            entries: duplicates,
            retrieveNewRecords: true,
            retrieveColumns: ['report_id']);
        // This is not a robust check that the insertion went okay
        // If it proves insufficient enough to merit the performance hit,
        // reconstruct the objects and compare using Object equality.
        if (kDebugMode) {
          assert(checkList.length == duplicates.length,
              'Failed to properly insert duplicates.');
        } else {
          if (checkList.length != duplicates.length) {
            throw Exception('Failed to properly insert duplicates.');
          }
        }
      }
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Returns a list of closed reports (if they happen to be needed for the application)
  /// Throws on an invalid database retrieval
  ///
  ///  NOTE: in integration testing, check that stringified enumerations are
  ///  the required value type
  Future<List<Report>> getClosed() async {
    try {
      final data =
          await _databaseService.getEntries(table: 'reports', filters: [
        DatabaseFilter(
            column: 'progress',
            operator: 'eq',
            value: ProgressStatus.closed.toEntity())
      ]);
      return data.map((e) => Report.fromEntity(e)).toList(growable: false);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Called on updates to the reports to notify all subscribers automatically
  /// Throws on an invalid database or notification operations
  /// All callers of this method need to handle or throw up.

  Future<void> _notifySubscribers({required Report report}) async {
    final message = report_utils.generateReportMessage(r: report);
    // Get the list of subscribers.
    final subscriberData = await _databaseService.getEntries(
        table: 'subscriptions',
        columns: [
          'method',
          'profiles(*)'
        ],
        filters: [
          DatabaseFilter(column: 'report_id', operator: 'eq', value: report.id)
        ]);

    // Flatten the nested hashmap.
    final subscriberInfo = subscriberData.map((e) {
      final sub = e['profiles'] ?? {};
      return {
        'method': e['method'],
        'fcm_token': sub['fcm_token'],
        'email': sub['email'],
        'phone': sub['phone']
      };
    }).toList();
    _notificationService.sendNotifications(
        message: message, clientInfo: subscriberInfo, payload: report.id);
  }

  DuplicateSeverity _measureDuplicate(
      {required Report r1, required Report r2}) {
    num score = report_utils.duplicateReportScore(r1: r1, r2: r2);
    return switch (score) {
      < 0.33 => DuplicateSeverity.unlikely,
      >= 0.33 && < 0.66 => DuplicateSeverity.possible,
      >= 0.66 => DuplicateSeverity.suspected,
      // This should never happen; if it does, there's a bug.
      _ => throw Exception("Invalid score: $score")
    };
  }

  /// Basic login function, nearly identical to the client app
  /// If the Employee object (ie. profile data to be used? in the GUI) is not
  /// set, grab the data.
  /// Throws on failure to retrieve from the database.
  /// Throws up exceptions raised during login.
  ///
  /// Returns true/false based on a successful log-in (ie proper credentials).
  ///
  /// Accounts should be assumed to be already placed in the database by a DA or similar.
  Future<bool> logIn({required String email, required String password}) async {
    try {
      if (_loginService.hasSession) {
        loggedIn.value = true;
        if (null == _employee || _loginService.userID != _employee?.uuid) {
          await _getEmployeeData();
        }
        return true;
      }

      if (await _loginService.logIn(email: email, password: password)) {
        loggedIn.value = true;
        await _getEmployeeData();
        return true;
      }
      return false;
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

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

  Future<void> _getEmployeeData() async {
    final employeeData = await _databaseService
        .getEntry(table: 'employees', filters: [
      DatabaseFilter(column: 'id', operator: 'eq', value: _loginService.userID)
    ]);
    _employee = Employee.fromEntity(entity: employeeData);
  }

  void _logError(
      {required Exception exception, required StackTrace stacktrace}) {
    log("Exception: ${exception.toString()}\n StackTrace: $stacktrace");
  }
}
