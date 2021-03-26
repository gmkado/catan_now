import 'package:catan_now/database.dart';
import 'package:get/get.dart';

import 'controller.dart';

class HomeBindings extends Bindings {
  @override
  Future<void> dependencies() async {
    // Get.lazyPut<Database>(() => CloudFirestoreDatabase.create());
    var db =
        await Get.putAsync<Database>(() => CloudFirestoreDatabase.create());
    await Get.putAsync(() => Controller.getController(db!));
  }
}
