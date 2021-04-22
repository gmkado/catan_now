import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'mixins.dart';

/// TODO: removing a proposal should remove all references to it in Player.responses
/// Or some cleanup needs to happen so we don't store unnecessary data
class Proposal extends LocalStreamManager {
  final DocumentReference reference;
  final RxString owner = "".obs;
  final String id;
  final Rx<DateTime> timestamp = DateTime.now().obs;
  final RxMap<String, bool> responses = <String, bool>{}.obs;

  static const String keyTimestamp = "timestamp";
  static const String keyResponses = "responses";
  static const String keyOwner = "owner";

  Proposal._(this.reference)
      : this.id = reference.id,
        super(reference);

  void updateFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data();
    if (data == null) {
      // null means we got deleted, do nothing
      return;
    }

    if (data.containsKey(keyOwner)) owner(data[keyOwner]);

    if (data.containsKey(keyTimestamp)) {
      Timestamp ts = data[keyTimestamp];
      timestamp(ts.toDate());
    }

    if (data.containsKey(keyResponses)) {
      final r = Map<String, bool>.from(data[keyResponses]);
      responses(r);
    }
  }

  @override
  void subscribeToLocalChanges() {
    // subscribe to changes from user
    subscriptions
        .add(timestamp.listen((ts) => reference.update({keyTimestamp: ts!})));
    subscriptions
        .add(responses.listen((r) => reference.update({keyResponses: r})));
  }

  static Proposal fromReference(DocumentReference reference) =>
      Proposal._(reference);
}
