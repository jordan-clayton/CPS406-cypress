import 'dart:developer';

import '../interface/notification_service.dart';

// We might be able to implement this in time using mailer/gmail
class EmailNotificationServiceImpl implements EmailNotificationService {
  @override
  void sendNotifications(
      {required String message,
      List<Map<String, dynamic>>? clientInfo,
      dynamic payload}) {
    // This is just a mock impl at the moment.
    for (var client in (clientInfo ?? [])) {
      if (null == client['email']) {
        throw Exception('Client email missing!');
      }
      log('Sending email to client: ${client['email']!}');
    }
  }
}

// This is mostly for proof of concept: we will likely need twilio or something similar
class SmsNotificationServiceImpl implements SmsNotificationService {
  @override
  void sendNotifications(
      {required String message,
      List<Map<String, dynamic>>? clientInfo,
      dynamic payload}) {
    for (var client in (clientInfo ?? [])) {
      if (null == client['phone']) {
        throw Exception('Phone number missing!');
      }
      log('Sending sms to client: ${client['phone']}');
    }
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
    for (var client in (clientInfo ?? [])) {
      if (null == client['fcm-token']) {
        throw Exception('Client not set up for push notifications');
      }
      log('Sending push notification to client using token: ${client['fcm-token']}');
    }
  }
}
