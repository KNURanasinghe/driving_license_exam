import 'dart:async';
import 'package:driving_license_exam/models/subscription_models.dart';
import 'package:driving_license_exam/services/subscription_service.dart';
import 'package:driving_license_exam/services/api_service.dart';

class SubscriptionNotifier {
  static final SubscriptionNotifier _instance =
      SubscriptionNotifier._internal();
  factory SubscriptionNotifier() => _instance;
  SubscriptionNotifier._internal();

  // Stream controller for subscription updates
  final StreamController<UserSubscription?> _subscriptionController =
      StreamController<UserSubscription?>.broadcast();

  // Getter for the stream
  Stream<UserSubscription?> get subscriptionStream =>
      _subscriptionController.stream;

  // Current subscription cache
  UserSubscription? _currentSubscription;
  UserSubscription? get currentSubscription => _currentSubscription;

  // Fetch and update subscription
  Future<void> fetchAndUpdateSubscription() async {
    try {
      final userId = await StorageService.getID();
      if (userId == null) return;

      final response = await SubscriptionService.getUserSubscriptions(
        userId: userId,
        status: 'active',
      );

      if (response.success && response.data != null) {
        _currentSubscription = _getCurrentActivePlan(response.data!);
        _subscriptionController.add(_currentSubscription);
        print(
            "Subscription updated globally: ${_currentSubscription?.plan.name}");
      } else {
        _currentSubscription = null;
        _subscriptionController.add(null);
      }
    } catch (e) {
      print("Error updating subscription: $e");
      _subscriptionController.add(null);
    }
  }

  // Helper method to get current active plan
  UserSubscription? _getCurrentActivePlan(
      List<UserSubscription> subscriptions) {
    if (subscriptions.isEmpty) return null;

    final activeSubscriptions = subscriptions
        .where((sub) => sub.status.toLowerCase() == 'active' && !sub.isExpired)
        .toList();

    if (activeSubscriptions.isEmpty) return null;

    activeSubscriptions.sort((a, b) => b.endDate.compareTo(a.endDate));
    return activeSubscriptions.first;
  }

  // Manual update method (call this after successful payment)
  void updateSubscription(UserSubscription? subscription) {
    _currentSubscription = subscription;
    _subscriptionController.add(subscription);
  }

  // Dispose method
  void dispose() {
    _subscriptionController.close();
  }
}
