import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'mixins.dart';

class Player with LocalStreamManager {
  static final int defaultColor = Colors.grey.value;
  static const String defaultName = "";
  static const String keyColor = "color";
  static const String keyResponses = "responses";
  static const String keyName = "responses";

  final String id;
  final DocumentReference reference;

  final RxInt color = Player.defaultColor.obs;
  final RxString name = Player.defaultName.obs;
  final RxMap<String, bool> responses = <String, bool>{}.obs;

  Player._(this.reference) : id = reference.id {
    // subscribe to changes from cloud
    reference.snapshots().listen((s) {
      unsubscribeFromLocalChanges();
      updateFromSnapshot(s);
      subscribeToLocalChanges();
    });

    subscribeToLocalChanges();
  }

  /// subscribe to changes from user
  @override
  void subscribeToLocalChanges() {
    Function(dynamic) getUpdateFunction(key) {
      void updateReference(value) {
        printChange(Player, id, key, value, local: true);
        reference.update({key: value});
      }

      return updateReference;
    }

    subscriptions.add(color.listen(getUpdateFunction(keyColor)));

    subscriptions.add(responses.listen(getUpdateFunction(keyResponses)));

    subscriptions.add(name.listen(getUpdateFunction(keyName)));
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
