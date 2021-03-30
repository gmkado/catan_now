import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Proposal {
  late String owner;
  final String id;
  final Rx<DateTime> timestamp = DateTime.now().obs;

  static const String keyTimestamp = "timestamp";
  static const String keyOwner = "owner";

  Proposal._(this.id);

  static void updateFromSnapshot(Proposal proposal, DocumentSnapshot snapshot) {
    proposal.owner = snapshot.data()![keyOwner];

    try {
      Timestamp dt = snapshot.data()![keyTimestamp];
      proposal.timestamp(dt.toDate());
    } catch (e) {
      // how to react here??
      print("Failed to get timestamp from proposal data: " + e.toString());
    }
  }

  static Proposal fromReference(DocumentReference reference) {
    final proposal = Proposal._(reference.id);

    // subscribe to cloud changes
    reference.snapshots().listen((s) => updateFromSnapshot(proposal, s));

    // subscribe to changes from user
    proposal.timestamp.listen((ts) => reference.update({keyTimestamp: ts!}));

    return proposal;
  }
}
