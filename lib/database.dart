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
  Future<Player> createPlayer(String id);
  Future<Proposal> createProposal(Player player, DateTime dateTime);
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
    final localPlayerIds = players.map((x) => x.id);
    final remotePlayerIds = snapShots.docs.map((x) => x.id);

    final deletedPlayers =
        players.where((x) => !remotePlayerIds.contains(x.id));

    if (deletedPlayers.isNotEmpty) {
      print("Cloud Players removed ${deletedPlayers.length}");
      players.removeWhere((x) => deletedPlayers.contains(x));
    }

    // add any new players
    final addedPlayers = snapShots.docs
        .where((x) => !localPlayerIds.contains(x.id))
        .map((x) => x.reference)
        .map(Player.fromReference);
    if (addedPlayers.isNotEmpty) {
      print("Cloud Players added ${addedPlayers.length}");
      players.addAll(addedPlayers);
    }
  }

  void updateProposals(QuerySnapshot snapShots) {
    // delete any removed players
    final localProposalIds = proposals.map((x) => x.id);
    final remoteProposalIds = snapShots.docs.map((x) => x.id);

    final deletedProposals =
        proposals.where((x) => !remoteProposalIds.contains(x.id));

    if (deletedProposals.isNotEmpty) {
      print("Cloud Proposal removed ${deletedProposals.length}");
      proposals.removeWhere((x) => deletedProposals.contains(x));
    }

    // add any new players
    final addedProposals = snapShots.docs
        .where((x) => !localProposalIds.contains(x.id))
        .map((x) => x.reference)
        .map(Proposal.fromReference);
    if (addedProposals.isNotEmpty) {
      print("Cloud Proposals added ${addedProposals.length}");
      proposals.addAll(addedProposals);
    }
  }

  Future<Player> createPlayer(String id) async {
    var currentPlayerRef = playersRef.doc(id);
    await currentPlayerRef.set({Player.keyColor: Player.defaultColor});

    print("Local Players added $id");
    return Player.fromReference(currentPlayerRef);
  }

  @override
  Future<Proposal> createProposal(
      Player currentPlayer, DateTime datetime) async {
    var proposalRef = await proposalsRef.add({
      Proposal.keyOwner: currentPlayer.id,
      Proposal.keyTimestamp: datetime,
    });

    // we should be accepting this time by default since we're creating it
    currentPlayer.responses[proposalRef.id] = true;
    print("Local Proposals added ${proposalRef.id}");
    return Proposal.fromReference(proposalRef);
  }
}
