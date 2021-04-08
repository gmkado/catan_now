import 'package:catan_now/player.dart';
import 'package:catan_now/proposal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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

class HeaderView extends GetView<Controller> {
  @override
  Widget build(context) {
    return Row(children: [
      Expanded(flex: 1, child: Text("When?")),
      Expanded(
          flex: 1,
          child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: controller.players
                  .map((p) => SizedBox(
                      width: 60,
                      child: Obx(() => RawMaterialButton(
                          shape: CircleBorder(),
                          child: Text(getPlayerName(p)),
                          fillColor: Color(p.color.value),
                          onPressed: () => {}))))
                  .toList()))),
    ]);
  }

  String getPlayerName(Player p) =>
      p.name.value! == "" ? p.id[0] : p.name.value!;
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
            Expanded(child: Text(getTimeString()), flex: 1),
            Expanded(
              flex: 1,
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: controller.players
                        .map((p) => Obx(() => PlayerResponseView(p,
                            response: p.responses[proposal.id],
                            onPressed: onPressed)))
                        .toList(),
                  )),
            )
          ],
        ));
  }

  String getTimeString() {
    var time = proposal.timestamp()!;
    var newMinute = (time.minute / 15).round() * 15;
    var newHour = newMinute == 60 ? time.hour + 1 : time.hour;
    var displayTime = new DateTime(time.year, time.month, time.day, newHour,
        newMinute, time.second, time.millisecond, time.microsecond);

    final formatter = DateFormat('jm');
    return formatter.format(displayTime);
  }

  void onPressed(Player player) {
    // only allow updates if we are the player
    if (player == controller.player) {
      cycleResponse(player);
    }
  }

  /// Go from no-response to accepted (true) to rejected (false)
  void cycleResponse(Player player) {
    final responses = player.responses;

    if (responses.containsKey(proposal.id)) {
      if (responses[proposal.id]!)
        responses[proposal.id] = false;
      else
        responses.remove(proposal.id);
    } else {
      responses[proposal.id] = true;
    }
  }
}

class PlayerResponseView extends GetView<Controller> {
  final Player player;
  final void Function(Player) onPressed;
  final bool? response;

  PlayerResponseView(this.player,
      {required this.response, required this.onPressed});

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

  String getText() {
    switch (response) {
      case true:
        return "o";
      case false:
        return "x";
      default:
        return "?";
    }
  }

  Color getColor() {
    var baseColor = Color(this.player.color());
    if (response == null) {
      return baseColor.withAlpha(100);
    }
    return baseColor;
  }
}

class EditPlayer extends GetView<Controller> {
  final textController = TextEditingController();

  @override
  Widget build(context) {
    var color = Color(controller.player.color());
    textController.text = controller.player.name()!;
    return AlertDialog(
      title: const Text('Edit Player'),
      content: Column(
        children: [
          TextFormField(
              controller: textController,
              decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter your name')),
          SingleChildScrollView(
              child: BlockPicker(
            pickerColor: color,
            onColorChanged: (c) => color = c,
            // showLabel: true,
            // pickerAreaHeightPercent: 0.8,
          )),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            controller.player.color(color.value);
            controller.player.name(textController.text);
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
          SizedBox(height: 60, child: HeaderView()),
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
                  onPressed: () async =>
                      await controller.createProposal(DateTime.now())))),
        ]));
  }
}
