import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Player {
  final RxInt color = Player.defaultColor.obs;
  final String id;

  static final int defaultColor = Colors.grey.value;
  static const String keyColor = "color";

  Player._(this.id);

  void updateFromSnapshot(DocumentSnapshot snapshot) {
    try {
      int c = snapshot.data()![keyColor];
      if (c != color.value) {
        printChange(Player, id, keyColor, color, local: false);
        color(c);
      }
    } catch (e) {
      print("Failed to get color from player data: " + e.toString());
    }
  }

  static Player fromReference(DocumentReference reference) {
    final player = Player._(reference.id);

    // subscribe to changes from cloud
    reference.snapshots().listen((s) => player.updateFromSnapshot(s));

    // subscribe to changes from user
    player.color.listen((c) {
      printChange(player.runtimeType, player.id, keyColor, c, local: true);
      reference.update({keyColor: c});
    });
    return player;
  }
}

void printChange(Type type, String id, String field, newval,
    {required bool local}) {
  final source = local ? "Local" : "Cloud";
  final dest = local ? "Cloud" : "Local";
  print('$source $id.$field=$newval, updating $dest');
}
