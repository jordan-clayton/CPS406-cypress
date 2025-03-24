import 'notification_service.dart';

// We might be able to implement this in time using mailer/gmail
class EmailNotificationServiceImpl implements EmailNotificationService {
  @override
  void sendNotifications(
      {required String message,
      List<Map<String, dynamic>>? clientInfo,
      dynamic payload}) {
    // TODO: implement sendNotifications
    throw UnimplementedError('EmailNotificationImpl not implemented');
  }
}

// This is mostly for proof of concept: we will likely need twilio or something similar
class SmsNotificationServiceImpl implements SmsNotificationService {
  @override
  void sendNotifications(
      {required String message,
      List<Map<String, dynamic>>? clientInfo,
      dynamic payload}) {
    // TODO: implement sendNotifications
    throw UnimplementedError('SmsNotificationImpl not implemented');
  }
}

// We might be able to implement this in time with firebase FCM
// I'm not 100% sure how FCM works, how to handle
class PushNotificationServiceImpl implements PushNotificationService {
  @override
  void sendNotifications(
      {required String message,
      List<Map<String, dynamic>>? clientInfo,
      dynamic payload}) {
    // TODO: implement sendNotifications
    throw UnimplementedError('PushNotificationImpl not implemented');
  }
}
