import 'package:catan_now/player.dart';
import 'package:catan_now/proposal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

import 'bindings.dart';
import 'controller.dart';

void main() async {
  var bindings = HomeBindings();
  await bindings.dependencies();

  runApp(GetMaterialApp(
    initialRoute: '/home',
    getPages: [GetPage(name: '/home', page: () => Home(), binding: bindings)],
  ));
}

class ProposalView extends GetView<Controller> {
  final Proposal proposal;
  ProposalView(this.proposal);

  @override
  Widget build(context) {
    return SizedBox(
        height: 50,
        child: Row(
          children: [
            Flexible(child: Text(proposal.timestamp.toString())),
            Expanded(
                child: Obx(() => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index)
                      {
                        final player = controller.players[index];
                        return Obx(() => PlayerResponseView(player,
                        response: proposal.responses.putIfAbsent(player.id, () => null),
                        onPressed: onPressed));
                      },
                      itemCount: controller.players.length,
                      // shrinkWrap: true,
                    )))
          ],
        ));
  }

  void onPressed(Player player){
    // only allow updates if we are the player
    if(player == controller.player) {
      proposal.cycleResponse(player);
    }
  }

}

class PlayerResponseView extends GetView<Controller> {
  final Player player;
  final void Function(Player) onPressed;
  final bool? response;

  PlayerResponseView(this.player, {required this.response, required this.onPressed});

  @override
  Widget build(context) {
    return SizedBox(
        width: 60,
        child: Obx(() => RawMaterialButton(
            shape: CircleBorder(),
            child: Text(getText()),
            fillColor: getColor(),
            onPressed: () => onPressed(player))));
  }
  String getText(){
    switch(response) {
      case true:
        return "o";
      case false:
        return "x";
      default:
        return player.id[0];
    }
  }

  Color getColor(){
    var baseColor = Color(this.player.color());
    if(response == null) {
      return baseColor.withAlpha(100);
    }
    return baseColor;
  }
}

class EditPlayer extends GetView<Controller> {
  @override
  Widget build(context) {
    var color = Color(controller.player.color());

    return AlertDialog(
      title: const Text('Pick a color'),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: color,
          onColorChanged: (c) => color = c,
          // showLabel: true,
          // pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Got it'),
          onPressed: () {
            controller.player.color(color.value);
            Get.back();
          },
        ),
      ],
    );
  }
}

class Home extends GetView<Controller> {
  @override
  Widget build(context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Who wants to play Catan?"),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => Get.to(() => EditPlayer()),
            )
          ],
        ),
        body: Column(children: [
          Expanded(
              child: Center(
                  child: Obx(() => ListView.builder(
                      itemCount: controller.proposals.length,
                      itemBuilder: (context, index) =>
                          ProposalView(controller.proposals[index]))))),
          Center(
              child: Obx(() => MaterialButton(
                  shape: CircleBorder(),
                  color: Color(controller.player.color()),
                  textColor: Colors.white,
                  padding: EdgeInsets.all(32),
                  child: Text("CATAN?"),
                  onPressed: () async => await controller.createProposal(DateTime.now())))),
        ]));
  }
}
