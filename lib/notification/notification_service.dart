import '../models/subscription.dart';

abstract interface class NotificationService {
  void sendNotifications(List<Subscription> subscriptions);
  void sendNotification(Subscription subscription);
}
