import 'dart:async';

mixin LocalStreamManager {
  final List<StreamSubscription> subscriptions = [];
  void unsubscribeFromLocalChanges() {
    subscriptions.forEach((element) => element.cancel());
    subscriptions.clear();
  }

  subscribeToLocalChanges();
}
