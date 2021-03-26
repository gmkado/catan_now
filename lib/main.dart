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

class EditPlayer extends GetView<Controller> {
  @override
  Widget build(context) {
    Color color = controller.player.color()!;

    return AlertDialog(
      title: const Text('Pick a color'),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: controller.player.color()!,
          onColorChanged: (c) => color = c,
          // showLabel: true,
          // pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Got it'),
          onPressed: () {
            controller.player.color(color);
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
            onPressed: () => Get.to(EditPlayer()),
          )
        ],
      ),
      body: Center(
          child: Obx(() => MaterialButton(
              shape: CircleBorder(),
              color: controller.player.color(),
              textColor: Colors.white,
              padding: EdgeInsets.all(32),
              child: Text("CATAN?"),
              onPressed: () => controller.createRequest(DateTime.now())))),
    );
  }
}
