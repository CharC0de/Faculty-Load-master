import 'package:get/get.dart';

class Responsive {
  static double verticalSize(double size) {
    double height = Get.height;
    return height * size / 687;
  }
  static double horizontalSize(double size) {
    double width = Get.width;
    return width * size / 360;
  }
}
