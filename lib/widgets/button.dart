import 'package:faculty_load/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButton extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final bool showCircularBar;
  const MyButton({super.key, required this.text, this.onTap, this.showCircularBar = false});

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width * 0.8,
        height: 50,
        decoration: BoxDecoration(color: mainColor, borderRadius: BorderRadius.circular(17.0)),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15.5),
              ),
              Visibility(
                visible: showCircularBar,
                child: const SizedBox(height: 15, width: 15, child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
