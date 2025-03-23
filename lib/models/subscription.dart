import 'package:equatable/equatable.dart';

enum NotificationMethod implements Comparable<NotificationMethod> {
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

  @override
  int compareTo(NotificationMethod other) => index - other.index;
}

class SubscriptionDTO {
  final int reportID;
  final NotificationMethod notificationMethod;
  final String contact;

  const SubscriptionDTO(
      {required this.reportID,
      required this.notificationMethod,
      required this.contact});
}

class Subscription extends Equatable implements Comparable<Subscription> {
  final String userID;
  final int reportID;
  final NotificationMethod notificationMethod;

  const Subscription(
      {required this.userID,
      required this.reportID,
      required this.notificationMethod});

  Subscription.fromEntity(Map<String, dynamic> entity)
      : userID = entity['user_id'] as String,
        reportID = entity['report_id'] as int,
        notificationMethod =
            NotificationMethod.fromString(entity['notification_method']);

  Map<String, dynamic> toEntity() => {
        'user_id': userID,
        'report_id': reportID,
        'notification_method': notificationMethod.name
      };

  @override
  List<Object> get props => [userID, reportID, notificationMethod];

  @override
  int compareTo(Subscription other) =>
      userID.compareTo(other.userID) +
      reportID.compareTo(other.reportID) +
      notificationMethod.compareTo(other.notificationMethod);
}
