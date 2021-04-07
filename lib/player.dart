import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

mixin LocalStreamManager {
  final List<StreamSubscription> subscriptions = [];
  void unsubscribeFromLocalChanges() {
    subscriptions.forEach((element) => element.cancel());
    subscriptions.clear();
  }

  subscribeToLocalChanges();
}

class Player with LocalStreamManager {
  final RxInt color = Player.defaultColor.obs;
  final String id;
  final DocumentReference reference;
  final RxMap<String, bool> responses = <String, bool>{}.obs;
  static final int defaultColor = Colors.grey.value;
  static const String keyColor = "color";
  static const String keyResponses = "responses";

  Player._(this.reference) : id = reference.id {
    // subscribe to changes from cloud
    reference.snapshots().listen((s) {
      unsubscribeFromLocalChanges();
      updateFromSnapshot(s);
      subscribeToLocalChanges();
    });

    subscribeToLocalChanges();
  }

  @override
  void subscribeToLocalChanges() {
    // subscribe to changes from user
    StreamSubscription sub = color.listen((c) {
      printChange(Player, id, keyColor, c, local: true);
      reference.update({keyColor: c});
    });
    subscriptions.add(sub);

    sub = responses.listen((r) {
      printChange(Player, id, keyResponses, r, local: true);
      reference.update({keyResponses: r});
    });
    subscriptions.add(sub);
  }

  void updateFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()!;

    if (data.containsKey(keyColor)) tryParseColor(data[keyColor]);

    if (data.containsKey(keyResponses)) tryParseResponses(data[keyResponses]);
  }

  void tryParseColor(dynamic data) {
    try {
      int c = data;
      if (c != color.value) {
        printChange(Player, id, keyColor, color, local: false);
        color(c);
      }
    } catch (e) {
      print("Failed to get color from player data: " + e.toString());
    }
  }

  void tryParseResponses(dynamic data) {
    try {
      final r = Map<String, bool>.from(data);
      printChange(Player, id, keyResponses, r, local: false);
      responses(r);
    } catch (e) {
      print("Failed to get responses from player data: " + e.toString());
    }
  }

  static Player fromReference(DocumentReference reference) =>
      Player._(reference);
}

void printChange(Type type, String id, String field, newval,
    {required bool local}) {
  final source = local ? "Local" : "Cloud";
  final dest = local ? "Cloud" : "Local";
  print('$source $id.$field=$newval, updating $dest');
}
