import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../db/db_service.dart';
import '../../db/query.dart';
import '../../models/report.dart';
import '../../models/subscription.dart';
import '../../models/user.dart';

// TODO: add a loginService
// TODO: add sorting
class ClientController {
  DatabaseService _service;
  User? _user;
  ValueNotifier<bool> loggedIn;

  ClientController(
      {required DatabaseService databaseService,
      User? user,
      bool loggedIn = false})
      : _service = databaseService,
        _user = user,
        loggedIn = ValueNotifier(loggedIn);

  void databaseService(newService) => {_service = newService};

  // Hook this into a FutureBuilder; catch errors in the GUI.
  Future<List<Report>> getOpenedReports() async {
    return Future(() async {
      try {
        final data = await _service.getEntries(table: 'reports', filters: [
          DatabaseFilter(column: 'progress', operator: 'neq', value: 'closed')
        ]);
        return data.map((e) => Report.fromEntity(e)).toList(growable: false);
      } on Exception catch (e, s) {
        // TODO: proper logging
        log(e.toString());
        return Future.error(e, s);
      }
    });
  }

  Future<void> subscribe({required SubscriptionDTO info}) async {
    if (!loggedIn.value || null == _user) {
      return _subscribeAnonymous(anon: info);
    }

    // Assert that the contact info is coherent.
    switch (info.notificationMethod) {
      case NotificationMethod.sms:
        assert(_user!.phone == info.contact);
        break;
      case NotificationMethod.email:
        assert(_user!.email == info.contact);
        break;
      case NotificationMethod.push:
        assert(_user!.fcmToken == info.contact);
        break;
    }

    Map<String, dynamic> entity = {
      'user_id': _user!.userID,
      'report_id': info.reportID,
      'notification_method': info.notificationMethod.name
    };

    await _service.createEntry(table: 'subscriptions', entry: entity);
  }

  Future<void> _subscribeAnonymous({required SubscriptionDTO anon}) async {
    final anonUser = User(userID: 'anonymous');
    switch (anon.notificationMethod) {
      case NotificationMethod.sms:
        anonUser.phone = anon.contact;
        break;
      case NotificationMethod.email:
        anonUser.email = anon.contact;
        break;
      case NotificationMethod.push:
        anonUser.fcmToken = anon.contact;
        break;
    }

    final data = await _service.createEntry(
      table: 'public.profiles',
      entry: anonUser.toEntity(),
      retrieveNewRecord: true,
      retrieveColumns: ['id'],
    );

    // This will throw on a null assignment.
    final String userID = data['id'];

    Map<String, dynamic> entity = {
      'id': userID,
      'report_id': anon.reportID,
      'notification_method': anon.notificationMethod
    };

    await _service.createEntry(table: 'subscriptions', entry: entity);
  }

  // TODO: supabase/database login
  // To authenticate users who want to read a report.
  // NOTE: this throws when user not found
  Future<void> logIn(
      {required String username, required String password}) async {
    // TODO: this should come from a loginService; both can be hooked into supabase.
    if (_service.validSession) {
      loggedIn.value = true;

      if (null == _user || _service.clientID != _user?.userID) {
        await _grabUserData();
      }
      return;
    }
    // TODO: implement loginService.
    // Client ID should come from the loginService.
    _grabUserData();
  }

  // NOTE: this throws when user not found
  Future<void> _grabUserData() async {
    final userData = await _service.getEntry(
        table: 'public.profiles',
        filters: [
          DatabaseFilter(column: 'id', operator: 'eq', value: _service.clientID)
        ]);

    _user = User.fromEntity(userData);
  }

  Future<void> registerUser({required User user}) async {
    await _service.createEntry(
      table: 'public.profiles',
      entry: user.toEntity(),
    );
  }
}
