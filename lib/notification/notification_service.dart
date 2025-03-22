import '../models/subscription.dart';

// TODO: handle this better -> try to avoid creating a subscription object if necessary
abstract interface class NotificationService {
  void sendNotifications(List<Subscription> subscriptions);

  void sendNotification(Subscription subscription);
}
