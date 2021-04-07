import 'dart:async';

import 'package:catan_now/player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Proposal {
  final DocumentReference reference;
  late String owner;
  final String id;
  final List<StreamSubscription> subscriptions = [];
  final Rx<DateTime> timestamp = DateTime.now().obs;
  final RxMap<String, bool?> responses = <String, bool?>{}.obs;
  static const String keyTimestamp = "timestamp";
  static const String keyOwner = "owner";
  static const String keyResponses = "responses";

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

    if (data.containsKey(keyResponses)) {
      final r = Map<String, bool?>.from(data[keyResponses]);
      printChange(Proposal, id, keyTimestamp, r, local: false);
      responses(r);
    }
  }

  void subscribeToLocalChanges() {
    // subscribe to changes from user
    subscriptions.add(timestamp.listen((ts) {
      printChange(Proposal, id, keyTimestamp, ts, local: true);
      reference.update({keyTimestamp: ts!});
    }));

    subscriptions.add(responses.listen((r) {
      printChange(Proposal, id, keyResponses, r, local: true);
      reference.update({
        keyResponses: r
      }); // TODO: we have some cycling happening due to this https://stackoverflow.com/questions/54117311/background-concurrent-copying-gc-freed-flutter#:~:text=It%20means%20your%20app%20is,you%20need%20to%20fix%20it.
    }));
  }

  void unsubscribeFromLocalChanges() {
    subscriptions.forEach((element) => element.cancel());
    subscriptions.clear();
  }

  static Proposal fromReference(DocumentReference reference) =>
      Proposal._(reference);

  /// Go from no-response (null) to accepted (true) to rejected (false)
  void cycleResponse(Player player) {
    switch (responses[player.id]) {
      case true:
        responses[player.id] = false;
        break;
      case false:
        responses[player.id] = null;
        break;
      default:
        responses[player.id] = true;
    }
  }
}
