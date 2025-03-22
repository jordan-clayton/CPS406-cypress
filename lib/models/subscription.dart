enum NotificationMethod {
  sms,
  email,
  push;

  factory NotificationMethod.fromString(String nm) =>
      switch (nm.toLowerCase()) {
        'sms' => NotificationMethod.sms,
        'email' => NotificationMethod.email,
        'push' => NotificationMethod.push,
        _ => throw FormatException('Invalid Notification format: $nm')
      };
}

// TODO: define equality; implement comparable
class Subscription {
  String userID;
  num reportID;
  NotificationMethod notificationMethod;

  Subscription(
      {required this.userID,
      required this.reportID,
      required this.notificationMethod});
  Subscription.fromEntity(Map<String, dynamic> entity)
      : userID = entity['user_id'] as String,
        reportID = entity['report_id'] as num,
        notificationMethod =
            NotificationMethod.fromString(entity['notification_method']);
}
