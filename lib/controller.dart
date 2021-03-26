import 'package:catan_now/database.dart';
import 'package:catan_now/player.dart';
import 'package:get/get.dart';

enum RequestState { none, pending, requested, retracting }

class Controller extends GetxController {
  Database database;
  Player player;
  late Rx<RequestState> state = RequestState.none.obs;

  Controller._(this.database, this.player);

  static Future<Controller> getController(Database database) async {
    var player = await database.getCurrentPlayer();
    return Controller._(database, player);
  }

  Future<void> createRequest(DateTime dateTime) async {
    database.createRequest(player, dateTime);
  }
}
