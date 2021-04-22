import 'package:catan_now/controller.dart';
import 'package:get/get.dart';
import 'controller.dart';

class HomeBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    await Get.putAsync<Controller>(() => Controller.create());
  }
}
