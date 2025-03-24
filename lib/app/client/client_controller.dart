import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../db/db_service.dart';
import '../../db/query.dart';
import '../../login/login_service.dart';
import '../../models/duplicates.dart';
import '../../models/flagged.dart';
import '../../models/report.dart';
import '../../models/subscription.dart';
import '../../models/user.dart';

class ClientController {
  DatabaseService _databaseService;
  LoginService _loginService;
  User? _user;
  ValueNotifier<bool> loggedIn;

  ClientController(
      {required DatabaseService databaseService,
      required LoginService loginService,
      User? user,
      bool loggedIn = false})
      : _databaseService = databaseService,
        _loginService = loginService,
        _user = user,
        loggedIn = ValueNotifier(loggedIn);

  void databaseService(newService) => {_databaseService = newService};

  void loginService(newService) => {_loginService = newService};

  /// To supply current reports to the frontend
  /// Includes unverified reports; convey this to the user in the map to encourage
  /// community moderation.
  ///  Throws on failure to retrieve data.
  ///
  ///  NOTE: in integration testing, check that stringified enumerations are
  ///  the required value type
  Future<List<Report>> getCurrentReports() async {
    try {
      final data =
          await _databaseService.getEntries(table: 'reports', filters: [
        DatabaseFilter(column: 'progress', operator: 'neq', value: 'closed'),
      ]);
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
    try {
      final entity = user.toEntity();
      entity['id'] = user.id;
      // This should implicitly filter based on the primary key.
      final response = await _databaseService.updateEntry(
          table: 'public.profiles', entry: entity, retrieveUpdatedRecord: true);

      assert(response['id'] == user.id);
      _user = User.fromEntity(response);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
    }
  }

  /// Subscribes a user to a report to listen for progress updates
  /// SubscriptionDTO holds all the relevant information for a subscription
  /// Since subscriptions can be anonymous, the contact method is embedded
  /// For registered users, expect this to match the user data.
  /// Throws on data incoherence.
  /// Throws on database failure.
  Future<void> subscribe({required SubscriptionDTO info}) async {
    try {
      if (!loggedIn.value || null == _user) {
        return _subscribeAnonymous(anon: info);
      }
      // Assert that the contact info is coherent.
      switch (info.notificationMethod) {
        case NotificationMethod.sms:
          assert(_user!.phone == info.contact);
        case NotificationMethod.email:
          assert(_user!.email == info.contact);
        case NotificationMethod.push:
          assert(_user!.fcmToken == info.contact);
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

    assert(null != data['id']);

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
    if (!loggedIn.value) {
      return Future.error(Exception("User not authenticated"));
    }
    try {
      final response = await _databaseService.createEntry(
          table: 'reports',
          entry: newReport.toEntity(),
          retrieveNewRecord: true,
          retrieveColumns: ['id']);

      assert(null != response['id']);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// For user-moderation, handles flagging of duplicate reports
  /// Throws on database failure, invalid login status.
  Future<void> reportDuplicate(
      {required int suspectedDupID, required int matchID}) async {
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
      assert(response['report_id'] == suspectedDupID &&
          response['match_id'] == matchID);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// For user-moderation, handles flagging of invalid/malicious reports
  /// Throws on database failure, invalid login status.
  Future<void> flagReport(
      {required int flaggedID, required FlaggedReason reason}) async {
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

      assert(response['report_id'] == flag.reportID &&
          FlaggedReason.fromString(response['reason']) == flag.reason);
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// To authenticate users who want to read a report.
  /// Throws Exceptions on failure to retrieve user data.
  Future<bool> logIn({required String email, required String password}) async {
    try {
      // If there's already a session, the user has a logged-in client
      // Update the client state at the controller level to expose data to the
      // GUI.
      if (_loginService.hasSession) {
        loggedIn.value = true;

        if (null == _user || _loginService.userID != _user?.id) {
          await _getUserData();
        }
        return true;
      }

      if (await _loginService.logIn(email: email, password: password)) {
        loggedIn.value = true;
        await _getUserData();
        return true;
      }

      return false;
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
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

        await _databaseService.createEntry(
          table: 'public.profiles',
          entry: _user!.toEntity(),
        );
      }
      return null != newUserID;
    } on Exception catch (e, s) {
      _logError(exception: e, stacktrace: s);
      return Future.error(e, s);
    }
  }

  /// Gets the user data from the public user table
  /// Throws on failure to retrieve data
  /// It is up to the caller to handle the exception
  Future<void> _getUserData() async {
    final userData = await _databaseService
        .getEntry(table: 'public.profiles', filters: [
      DatabaseFilter(column: 'id', operator: 'eq', value: _loginService.userID)
    ]);

    _user = User.fromEntity(userData);
  }

  void _logError(
      {required Exception exception, required StackTrace stacktrace}) {
    log("Exception: ${exception.toString()}\n StackTrace: $stacktrace");
  }
}
