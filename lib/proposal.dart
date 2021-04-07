import 'dart:async';

import 'package:catan_now/player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

/// TODO: removing a proposal should remove all references to it in Player.responses
/// Or some cleanup needs to happen so we don't store unnecessary data
class Proposal with LocalStreamManager {
  final DocumentReference reference;
  late String owner;
  final String id;
  final Rx<DateTime> timestamp = DateTime.now().obs;
  static const String keyTimestamp = "timestamp";
  static const String keyOwner = "owner";

  Proposal._(this.reference) : this.id = reference.id {
    // subscribe to cloud changes
    reference.snapshots().listen((s) {
      unsubscribeFromLocalChanges();
      updateFromSnapshot(s);
      subscribeToLocalChanges();
    });
    subscribeToLocalChanges();
  }

  void updateFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()!;

    if (data.containsKey(keyOwner)) owner = data[keyOwner];

    if (data.containsKey(keyTimestamp)) {
      DateTime dt = data[keyTimestamp].toDate();
      if (dt != timestamp()) {
        printChange(Proposal, id, keyTimestamp, dt, local: false);
        timestamp(dt);
      }
    }
  }

  @override
  void subscribeToLocalChanges() {
    // subscribe to changes from user
    subscriptions.add(timestamp.listen((ts) {
      printChange(Proposal, id, keyTimestamp, ts, local: true);
      reference.update({keyTimestamp: ts!});
    }));
  }

  static Proposal fromReference(DocumentReference reference) =>
      Proposal._(reference);
}
