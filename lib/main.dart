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
            Expanded(child: Text(proposal.timestamp.toString())),
            Expanded(
                child: Obx(() => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => PlayerView(
                        controller.players[index],
                        onPressed: () => {},
                      ),
                      itemCount: controller.players.length,
                      // shrinkWrap: true,
                    )))
          ],
        ));
  }
}

class PlayerView extends GetView<Controller> {
  final Player player;
  final void Function() onPressed;

  PlayerView(this.player, {required this.onPressed});

  @override
  Widget build(context) {
    return Center(
        child: Obx(() => RawMaterialButton(
            shape: CircleBorder(),
            child: Text(this.player.id[0]),
            fillColor: Color(this.player.color()),
            onPressed: onPressed)));
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
                  onPressed: () => controller.createProposal(DateTime.now())))),
        ]));
  }
}
