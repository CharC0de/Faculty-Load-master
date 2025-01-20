import 'dart:math';
import 'package:intl/intl.dart';

String filestamp() {
  return "${DateFormat('yyyyMMdd').format(DateTime.now())}_${Random().nextInt(900) + 100}";
}
