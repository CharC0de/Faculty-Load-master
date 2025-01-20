import 'package:faculty_load/data/api/api.dart';
import 'package:faculty_load/view/login/controller/login_controller.dart';
import 'package:faculty_load/view/signup/controller/signup_controller.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiClient());
    Get.lazyPut(() => SignUpController(Get.find()));
    Get.lazyPut(() => LoginController(Get.find()));
  }
}
