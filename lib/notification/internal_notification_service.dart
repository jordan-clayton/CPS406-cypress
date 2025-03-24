import 'package:collection/collection.dart';

import 'notification_service.dart';

class InternalNotifcationService implements NotificationService {
  SmsNotificationService _smsNotificationService;
  EmailNotificationService _emailNotificationService;
  PushNotificationService _pushNotificationService;

  InternalNotifcationService(
      {required SmsNotificationService sms,
      required EmailNotificationService email,
      required PushNotificationService push})
      : _smsNotificationService = sms,
        _emailNotificationService = email,
        _pushNotificationService = push;

  void smsNotificationService(newSms) => {_smsNotificationService = newSms};

  void emailNotificationService(newEmail) =>
      {_emailNotificationService = newEmail};

  void pushNotificationService(newPush) => {_pushNotificationService = newPush};

  @override
  void sendNotifications(
      {required String message,
      List<Map<String, dynamic>>? clientInfo,
      dynamic payload}) {
    final data =
        groupBy(clientInfo ?? [], (info) => info['notification_method']);

    _smsNotificationService.sendNotifications(
        message: message, clientInfo: data['sms']?.cast(), payload: payload);
    _emailNotificationService.sendNotifications(
        message: message, clientInfo: data['email']?.cast(), payload: payload);
    _pushNotificationService.sendNotifications(
        message: message, clientInfo: data['push']?.cast(), payload: payload);
  }
}
