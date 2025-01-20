import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TitleText extends StatelessWidget {
  const TitleText({
    Key? key,
    required this.title,
    this.size = "",
  }) : super(key: key);

  final String title;
  final String size;

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return SizedBox(
      width: width * 0.8,
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 25),
        textAlign: TextAlign.center,
      ),
    );
  }
}
