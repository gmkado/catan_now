import 'dart:io';

import 'package:catan_now/database.dart';
import 'package:catan_now/player.dart';
import 'package:catan_now/proposal.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Controller extends GetxController {
  Database database;
  late Player player;
  late RxList<Player> players;
  late RxList<Proposal> proposals;

  Controller._(this.database);

  Future<void> initialize() async {
    var info = await getDeviceInfo();
    players = database.players;
    proposals = database.proposals;

    // create a player with this id if it doesn't exist
    try {
      player = players.singleWhere((x) => x.id == info);
    } catch (e) {
      player = database.createPlayer(info);
    }
  }

  static Future<Controller> getController(Database database) async {
    var controller = Controller._(database);
    await controller.initialize();
    return controller;
  }

  Future<void> createProposal(DateTime dateTime) async {
    database.createProposal(player, dateTime);
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
