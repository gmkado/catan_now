import 'dart:async';

import 'package:catan_now/player.dart';
import 'package:catan_now/proposal.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

abstract class Database {
  abstract final RxList<Player> players;
  abstract final RxList<Proposal> proposals;
  Player createPlayer(String id);
  Proposal createProposal(Player player, DateTime dateTime);
}

class CloudFirestoreDatabase extends Database {
  static const bool USE_FIRESTORE_EMULATOR = false;

  late final DocumentReference defaultRoom;
  late final CollectionReference playersRef;
  late final CollectionReference proposalsRef;
  final RxList<Player> players = <Player>[].obs;
  final RxList<Proposal> proposals = <Proposal>[].obs;

  CloudFirestoreDatabase._(); // private constructor

  static Future<CloudFirestoreDatabase> create() async {
    var db = CloudFirestoreDatabase._();
    await db.init();
    return db;
  }

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    if (USE_FIRESTORE_EMULATOR) {
      FirebaseFirestore.instance.settings = const Settings(
          host: 'localhost:8080', sslEnabled: false, persistenceEnabled: false);
    }

    defaultRoom =
        (await FirebaseFirestore.instance.collection('gamerooms').get())
            .docs
            .first
            .reference;
    playersRef = defaultRoom.collection("players");
    proposalsRef = defaultRoom.collection("proposed");

    updatePlayers(await playersRef.snapshots().first);
    updateProposals(await proposalsRef.snapshots().first);
    playersRef.snapshots().listen(updatePlayers);
    proposalsRef.snapshots().listen(updateProposals);
  }

  void updatePlayers(QuerySnapshot snapShots) {
    // delete any removed players
    var playerIds = snapShots.docs.map((x) => x.id);
    players.removeWhere((x) => !playerIds.contains(x.id));

    // add any new players
    playerIds = players.map((s) => s.id);
    var newPlayerRefs = snapShots.docs
        .where((x) => !playerIds.contains(x.id))
        .map((x) => x.reference);
    players.addAll(newPlayerRefs.map(Player.fromReference));
  }

  void updateProposals(QuerySnapshot snapShots) {
    // TODO: for some reason we're not getting here
    // when a new proposal is created

    // delete any removed proposals
    var proposalIds = snapShots.docs.map((x) => x.id);
    proposals.removeWhere((x) => !proposalIds.contains(x.id));

    // add any new proposalIds
    proposalIds = proposals.map((s) => s.id);
    var newProposalRefs = snapShots.docs
        .where((x) => !proposalIds.contains(x.id))
        .map((x) => x.reference);
    proposals.addAll(newProposalRefs.map(Proposal.fromReference));
  }

  Player createPlayer(String id) {
    var currentPlayerRef = playersRef.doc(id);
    return Player.fromReference(currentPlayerRef);
  }

  @override
  Proposal createProposal(Player currentPlayer, DateTime datetime) {
    var proposalRef = proposalsRef.doc();
    proposalRef.set({
      Proposal.keyOwner: currentPlayer.id,
      Proposal.keyTimestamp: datetime,
    });

    return Proposal.fromReference(proposalRef);
  }
}
