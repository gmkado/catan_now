import 'dart:async';

import 'package:catan_now/player.dart';
import 'package:catan_now/proposal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info/device_info.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class Controller extends GetxController {
  static const bool USE_FIRESTORE_EMULATOR = true;

  late final DocumentReference defaultRoom;
  late final CollectionReference playersRef;
  late final CollectionReference proposalsRef;
  final RxList<Player> players = <Player>[].obs;
  final RxList<Proposal> proposals = <Proposal>[].obs;
  late final Player currentPlayer;

  late final String currentPlayerId;

  final double iconSize = 60;
  Controller._(); // private constructor

  static Future<Controller> create() async {
    var db = Controller._();
    await db.init();
    return db;
  }

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    currentPlayerId = await getDeviceInfo();
    if (USE_FIRESTORE_EMULATOR) {
      // HACK: hardcode my pixel 3a device id
      var host = currentPlayerId == "1de9723596c0795c"
          ? '192.168.86.228:8080' // https://stackoverflow.com/a/4779992/3525158
          : '10.0.2.2:8080'; // https://firebase.flutter.dev/docs/firestore/usage/#emulator-usage
      FirebaseFirestore.instance.settings =
          Settings(host: host, sslEnabled: false, persistenceEnabled: false);
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await messaging.requestPermission();
    }

    var roomsRef = FirebaseFirestore.instance.collection('gamerooms');

    defaultRoom = (await roomsRef.get())
        .docs
        .first // <-- ONLY ONE ROOM FOR NOW
        .reference;

    await FirebaseMessaging.instance.subscribeToTopic(defaultRoom.id);
    playersRef = defaultRoom.collection("players");
    proposalsRef = defaultRoom.collection("proposed");

    updatePlayers(await playersRef.snapshots().first);
    updateProposals(await proposalsRef.snapshots().first);

    try {
      currentPlayer = players.singleWhere((x) => x.id == currentPlayerId);
    } catch (e) {
      currentPlayer = await createPlayer(currentPlayerId);
    }

    playersRef.snapshots().listen(updatePlayers);
    proposalsRef.snapshots().listen(updateProposals);
  }

  void updatePlayers(QuerySnapshot snapShots) {
    final localPlayerIds = players.map((x) => x.id);
    final remotePlayerIds = snapShots.docs.map((x) => x.id);

    // delete any removed players from our local list
    final deletedPlayers =
        players.where((x) => !remotePlayerIds.contains(x.id));

    if (deletedPlayers.isNotEmpty) {
      print("Cloud Players removed ${deletedPlayers.length}");
      players.removeWhere((x) => deletedPlayers.contains(x));
    }

    // add any new players to our local list
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

    return Player.fromReference(currentPlayerRef);
  }

  Future<Proposal> createProposal(DateTime datetime) async {
    var proposalRef = await proposalsRef.add({
      Proposal.keyOwner: currentPlayer.id,
      Proposal.keyTimestamp: datetime,
      Proposal.keyResponses: {currentPlayer.id: true}
    });

    return Proposal.fromReference(proposalRef);
  }

  static Future<String> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

    if (Platform.isAndroid) {
      var build = await deviceInfoPlugin.androidInfo;
      return build.androidId; //UUID for Android
    } else if (Platform.isIOS) {
      var data = await deviceInfoPlugin.iosInfo;
      return data.identifierForVendor; //UUID for iOS
    } else {
      throw PlatformException(code: "Unexpected platform");
    }
  }
}
