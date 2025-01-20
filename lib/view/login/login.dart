// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/core/utils/responsive_size.dart';
import 'package:faculty_load/router/app_routes.dart';
import 'package:faculty_load/view/login/controller/login_controller.dart';
import 'package:faculty_load/widgets/Text_field.dart';
import 'package:faculty_load/widgets/button.dart';
import 'package:faculty_load/widgets/outlined_button.dart';
import 'package:faculty_load/widgets/title_text.dart';
import 'package:faculty_load/widgets/top_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    String title = "Login";
    String imgPath = "assets/images/faculty_load.png";
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TopImage(
                imgPath: imgPath,
                size: Responsive.horizontalSize(360 * 0.5),
              ),
              RichText(
                text: TextSpan(
                    text: "Faculty",
                    children: [
                      TextSpan(
                          text: " Load",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ))
                    ],
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              SizedBox(
                height: Responsive.verticalSize(50),
              ),
              MyTextField(
                controller: controller.emailController,
                hintText: "email address",
                keyboardType: TextInputType.emailAddress,
                width: width * 0.8,
                icon: const Icon(FontAwesomeIcons.at, size: 17),
              ),
              SizedBox(
                height: Responsive.verticalSize(20),
              ),
              MyTextField(
                controller: controller.passwordController,
                hintText: "password",
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                width: width * 0.8,
                icon: const Icon(Icons.lock_outline_rounded, size: 19),
              ),
              SizedBox(
                height: Responsive.verticalSize(30),
              ),
              GetBuilder<LoginController>(builder: (cont) {
                return MyButton(
                  showCircularBar: cont.isLoading.value,
                  onTap: () => cont.login(),
                  text: "Login",
                );
              }),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.signup),
                      child: Text(
                        "Register",
                        style: GoogleFonts.poppins(color: mainColor),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: Responsive.verticalSize(15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
