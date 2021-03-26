import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Player {
  Rx<Color> color;

  DocumentReference reference;

  Player._(this.color, this.reference) {
    color.listen((c) => this.reference.update({'color': c!.value}));
  }

  static Future<Player> fromReference(DocumentReference reference) async {
    var snapShot = await reference.get();
    Color color;
    try {
      int colorInt = snapShot.data()!['color'];
      color = Color(colorInt);
    } catch (e) {
      color = Colors.grey;
    }
    return Player._(color.obs, reference);
  }
}
