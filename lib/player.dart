import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Player {
  final RxInt color = Colors.grey.value.obs;
  final String id;

  static const String keyColor = "color";

  Player._(this.id);

  static void updateFromSnapshot(Player player, DocumentSnapshot snapshot) {
    try {
      int color = snapshot.data()![keyColor];
      print(
          'Cloud color for ${snapshot.id} = ${player.color.value} -> ${color}');
      player.color(color);
    } catch (e) {
      print("Failed to get color from player data: " + e.toString());
    }
  }

  static Player fromReference(DocumentReference reference) {
    final player = Player._(reference.id);

    // subscribe to changes from cloud
    reference.snapshots().listen((s) => updateFromSnapshot(player, s));

    // subscribe to changes from user
    player.color.listen((c) => reference.update({keyColor: c}));
    return player;
  }
}
