import 'package:catan_now/player.dart';
import 'package:catan_now/proposal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'bindings.dart';
import 'controller.dart';

// TODO: iphonr integration https://firebase.flutter.dev/docs/messaging/apple-integration/

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
      Expanded(flex: 1, child: Container()),
      Expanded(
        flex: 2,
        child: PlayerIconWidget(controller.currentPlayer),
      ),
      Expanded(
          flex: 3,
          child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: controller.players
                  .where((p) => p.id != controller.currentPlayer.id)
                  .map((p) => PlayerIconWidget(p))
                  .toList())))
    ]);
  }
}

class PlayerIconWidget extends GetView<Controller> {
  final Player player;

  PlayerIconWidget(this.player);

  @override
  Widget build(context) {
    return SizedBox(
        width: controller.iconSize,
        child: Obx(() => RawMaterialButton(
            shape: CircleBorder(),
            child: Text(player.name()!,
                style: Theme.of(context).textTheme.subtitle2),
            fillColor: getColor(player, highlight: true),
            onPressed: () => {
                  if (controller.currentPlayerId == player.id)
                    {Get.to(() => EditPlayerName())}
                })));
  }
}

class ProposalView extends GetView<Controller> {
  final Proposal proposal;
  ProposalView(this.proposal);

  @override
  Widget build(context) {
    final formatter = DateFormat('jm');
    return SizedBox(
        height: controller.iconSize,
        child: Row(
          children: [
            Expanded(
                child: Obx(() => Text(formatter.format(proposal.timestamp()!),
                    style: TextStyle(
                        fontWeight:
                            proposal.owner() == controller.currentPlayerId
                                ? FontWeight.bold
                                : FontWeight.normal))),
                flex: 1),
            Expanded(child: CurrentPlayerResponseView(proposal), flex: 2),
            Expanded(
              flex: 3,
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: controller.players
                        .where((p) => p.id != controller.currentPlayer.id)
                        .map((p) => Obx(() => PlayerResponseView(p,
                            response: proposal
                                .responses[p.id]))) // null == no response
                        .toList(),
                  )),
            )
          ],
        ));
  }
}

class CurrentPlayerResponseView extends GetView<Controller> {
  final Proposal proposal;
  CurrentPlayerResponseView(this.proposal);

  @override
  Widget build(context) {
    return Row(children: [
      ResponseButtonView(proposal, response: true),
      ResponseButtonView(proposal, response: false)
    ]);
  }
}

class ResponseButtonView extends GetView<Controller> {
  final Proposal proposal;
  final bool response;

  ResponseButtonView(this.proposal, {required this.response});

  @override
  Widget build(context) {
    return SizedBox(
        width: controller.iconSize,
        child: Obx(() => RawMaterialButton(
            shape: CircleBorder(),
            child: getIconForResponse(response),
            fillColor:
                getColor(controller.currentPlayer, highlight: isSelected()),
            onPressed: toggleResponse)));
  }

  void toggleResponse() {
    print("toggling " + proposal.id);
    isSelected()
        ? proposal.responses.remove(controller.currentPlayer.id)
        : proposal.responses[controller.currentPlayer.id] = response;
  }

  bool isSelected() =>
      response == proposal.responses[controller.currentPlayer.id];
}

class PlayerResponseView extends GetView<Controller> {
  final Player player;
  final bool? response;

  PlayerResponseView(this.player, {required this.response});

  @override
  Widget build(context) {
    return SizedBox(
        width: controller.iconSize,
        child: Obx(() => RawMaterialButton(
              shape: CircleBorder(),
              child: getIconForResponse(response),
              fillColor: getColor(player, highlight: response != null),
              onPressed: () => {},
            )));
  }
}

Widget getIconForResponse(bool? response) {
  switch (response) {
    case true:
      return Icon(Icons.check);
    case false:
      return Text("X");
    default:
      return Text("?");
  }
}

Color getColor(Player player, {required bool highlight}) =>
    Color(player.color()).withAlpha(highlight ? 255 : 50);

class EditPlayerColor extends GetView<Controller> {
  @override
  Widget build(context) {
    var color = Color(controller.currentPlayer.color());
    return AlertDialog(
      title: const Text('Pick a color'),
      content: Column(
        children: [
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
            controller.currentPlayer.color(color.value);
            Get.back();
          },
        ),
      ],
    );
  }
}

class EditPlayerName extends GetView<Controller> {
  final textController = TextEditingController();

  @override
  Widget build(context) {
    textController.text = controller.currentPlayer.name()!;
    return AlertDialog(
      title: const Text('Enter a Name'),
      content: Column(
        children: [
          TextFormField(
              controller: textController,
              decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter your name')),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            controller.currentPlayer.name(textController.text);
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
            onPressed: () => Get.to(() => EditPlayerColor()),
          )
        ],
      ),
      body: Column(children: [
        SizedBox(height: controller.iconSize, child: HeaderView()),
        Expanded(
            child: Center(
                child: Obx(() => ListView.builder(
                    itemCount: controller.proposals.length,
                    itemBuilder: (context, index) {
                      final proposal = controller.proposals[index];

                      return Obx(() {
                        Widget view = ProposalView(proposal);
                        if (proposal.owner() == controller.currentPlayer.id) {
                          view = Dismissible(
                            background: Container(color: Colors.red),
                            key: Key(proposal.id),
                            child: view,
                            onDismissed: (_) async =>
                                await proposal.reference.delete(),
                          );
                        }
                        if (proposal.gameCriteriaMet()!) {
                          view = Container(
                            child: view,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.green)),
                          );
                        }
                        return view;
                      });
                    })))),
        Center(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: Obx(() => MaterialButton(
                    shape: CircleBorder(),
                    color: Color(controller.currentPlayer.color()),
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
                      await createProposal(DateTime(
                          dt.year, dt.month, dt.day, time.hour, time.minute));
                    },
                    onPressed: () async =>
                        await createProposal(getRoundedTime()))))),
      ]),
    );
  }

  Future createProposal(DateTime dt) async {
    try {
      // check if a proposal for this datetime already exists
      var existing =
          controller.proposals.firstWhere((p) => p.timestamp() == dt);

      if (existing.responses[controller.currentPlayer.id] ?? false) {
        Get.defaultDialog(
            middleText: "You've already accepted a proposal for this time");
      } else {
        Get.defaultDialog(
            middleText: "A proposal already exists for ${dt.toString()}" +
                "\n\nDo you want to accept that one instead?",
            onConfirm: () {
              existing.responses[controller.currentPlayer.id] = true;
              Get.back();
            });
      }
    } catch (StateError) {
      // no matching proposal exists, create a new one
      await controller.createProposal(dt);
    }
  }

  DateTime getRoundedTime() {
    var dt = DateTime.now();
    var newMinute = (dt.minute / 15).round() * 15;
    return new DateTime(dt.year, dt.month, dt.day, dt.hour, newMinute);
  }
}
