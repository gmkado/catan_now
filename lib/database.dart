import 'dart:io';

import 'package:catan_now/player.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

abstract class Database {
  Future<Player> getCurrentPlayer();

  void createRequest(Player player, DateTime dateTime);
}

class CloudFirestoreDatabase extends Database {
  static const bool USE_FIRESTORE_EMULATOR = false;

  late final QueryDocumentSnapshot defaultRoom;

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
            .first;
  }

  Future<Player> getCurrentPlayer() async {
    var playersRef = defaultRoom.reference.collection("players");
    var players = (await playersRef.get()).docs;
    var info = await getDeviceInfo();

    late DocumentReference currentPlayerRef;
    try {
      currentPlayerRef = players.singleWhere((x) => x.id == info).reference;
    } catch (e) {
      currentPlayerRef = playersRef.doc(info);
    }

    return await Player.fromReference(currentPlayerRef);
  }

  Future<String> getDeviceInfo() async {
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

  @override
  Future<void> createRequest(Player currentPlayer, DateTime datetime) async {
    var proposedRef = defaultRoom.reference.collection("proposed");
    var proposed = (await proposedRef.get()).docs;

    DocumentReference proposalRef;
    try {
      proposalRef = proposed
          .singleWhere((p) => p.data()!['owner'] == currentPlayer.reference.id)
          .reference;
    } catch (e) {
      proposalRef = proposedRef.doc();
      await proposalRef.set({"owner": currentPlayer.reference.id});
    }

    await proposalRef.update({'timestamp': datetime});
  }
}
