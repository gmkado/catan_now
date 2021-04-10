import 'package:catan_now/player.dart';
import 'package:catan_now/proposal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'bindings.dart';
import 'controller.dart';
import 'expandable.dart';

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
      Expanded(
          flex: 1,
          child: Text("When?", style: Theme.of(context).textTheme.subtitle2)),
      Expanded(
          flex: 1,
          child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: controller.players
                  .map((p) => SizedBox(
                      width: 60,
                      child: Obx(() => RawMaterialButton(
                          shape: CircleBorder(),
                          child: Text(getPlayerName(p),
                              style: Theme.of(context).textTheme.subtitle2),
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
  Widget build(context) => SizedBox(
      height: 50,
      child: Row(
        children: [
          Expanded(child: buildTime(), flex: 1),
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
  final formatter = DateFormat('jm');
  Text buildTime() => Text(formatter.format(proposal.timestamp()!),
      style: TextStyle(
          fontWeight: proposal.owner() == controller.player.id
              ? FontWeight.bold
              : FontWeight.normal));

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
            child: getIcon(),
            fillColor: getColor(),
            onPressed: () => onPressed(player))));
  }

  Widget getIcon() {
    switch (response) {
      case true:
        return Icon(Icons.check);
      case false:
        return Text("X");
      default:
        return Text("?");
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
                    itemBuilder: (context, index) {
                      final proposal = controller.proposals[index];
                      final view = ProposalView(proposal);
                      return Obx(() => proposal.owner() == controller.player.id
                          ? Dismissible(
                              background: Container(color: Colors.red),
                              key: Key(proposal.id),
                              child: view,
                              onDismissed: (_) async =>
                                  await proposal.reference.delete(),
                            )
                          : view);
                    })))),
        Center(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Obx(() => MaterialButton(
                    shape: CircleBorder(),
                    color: Color(controller.player.color()),
                    textColor: Colors.white,
                    padding: EdgeInsets.all(32),
                    child: Icon(CupertinoIcons.hexagon),
                    onLongPress: () async {
                      var time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: 10, minute: 47),
                        builder: (BuildContext context, Widget? child) {
                          return MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );

                      if (time == null) return;
                      var dt = DateTime.now();
                      await controller.createProposal(DateTime(
                          dt.year, dt.month, dt.day, time.hour, time.minute));
                    },
                    onPressed: () async =>
                        await controller.createProposal(getTimeString()))))),
      ]),
    );
  }

  DateTime getTimeString() {
    var dt = DateTime.now();
    var newMinute = (dt.minute / 15).round() * 15;
    var newHour = newMinute == 60 ? dt.hour + 1 : dt.hour;
    return new DateTime(dt.year, dt.month, dt.day, newHour, newMinute,
        dt.second, dt.millisecond, dt.microsecond);
  }
}
