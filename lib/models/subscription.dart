import 'package:equatable/equatable.dart';

enum NotificationMethod implements Comparable<NotificationMethod> {
  sms,
  email,
  push;

  factory NotificationMethod.fromString(String nm) =>
      switch (nm.toLowerCase()) {
        'sms' => sms,
        'email' => email,
        'push' => push,
        _ => throw FormatException('Invalid Notification format: $nm')
      };

  // If we add more categories with complex string representations,
  // override toString and replace uses of ProblemCategory.name
  @override
  int compareTo(NotificationMethod other) => index.compareTo(other.index);

  @override
  toString() => name;
  toEntity() => name;
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

  factory Subscription.fromEntity(Map<String, dynamic> entity) => Subscription(
      userID: entity['user_id'] as String,
      reportID: entity['report_id'] as int,
      notificationMethod: NotificationMethod.fromString(entity['method']));

  Map<String, dynamic> toEntity() => {
        'user_id': userID,
        'report_id': reportID,
        'method': notificationMethod.toEntity()
      };

  @override
  List<Object> get props => [userID, reportID, notificationMethod];

  @override
  int compareTo(Subscription other) =>
      userID.compareTo(other.userID) +
      reportID.compareTo(other.reportID) +
      notificationMethod.compareTo(other.notificationMethod);
}
