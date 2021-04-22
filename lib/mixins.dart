import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class LocalStreamManager {
  LocalStreamManager(DocumentReference reference) {
    reference.snapshots().listen((s) {
      unsubscribeFromLocalChanges();
      updateFromSnapshot(s);
      subscribeToLocalChanges();
    });
    subscribeToLocalChanges();
  }

  final List<StreamSubscription> subscriptions = [];
  void unsubscribeFromLocalChanges() {
    subscriptions.forEach((element) => element.cancel());
    subscriptions.clear();
  }

  subscribeToLocalChanges();
  updateFromSnapshot(DocumentSnapshot snapshot);
}
