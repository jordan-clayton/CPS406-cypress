abstract interface class NotificationService {
  void sendNotifications(
      {required String message,
      List<Map<String, dynamic>>? clientInfo,
      dynamic payload});
}

abstract interface class EmailNotificationService
    implements NotificationService {}

abstract interface class SmsNotificationService
    implements NotificationService {}

abstract interface class PushNotificationService
    implements NotificationService {}
