import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'mixins.dart';

class Player extends LocalStreamManager {
  static final int defaultColor = Colors.grey.value;
  static const String defaultName = "?";
  static const String keyColor = "color";
  static const String keyName = "name";

  final String id;
  final DocumentReference reference;

  final RxInt color = Player.defaultColor.obs;
  final RxString name = Player.defaultName.obs;

  Player._(this.reference)
      : id = reference.id,
        super(reference);

  /// subscribe to changes from user
  @override
  void subscribeToLocalChanges() {
    subscriptions.add(color.listen((c) => reference.update({keyColor: c})));
    subscriptions.add(name.listen((n) => reference.update({keyName: n})));
  }

  void updateFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()!;

    if (data.containsKey(keyColor)) {
      int c = data[keyColor];
      if (c != color.value) {
        color(c);
      }
    }
    if (data.containsKey(keyName)) {
      name(data[keyName]);
    }
  }

  static Player fromReference(DocumentReference reference) =>
      Player._(reference);
}
