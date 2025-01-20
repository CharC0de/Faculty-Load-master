import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/core/utils/responsive_size.dart';
import 'package:faculty_load/router/app_routes.dart';
import 'package:faculty_load/view/signup/controller/signup_controller.dart';
import 'package:faculty_load/widgets/Text_field.dart';
import 'package:faculty_load/widgets/button.dart';
import 'package:faculty_load/widgets/outlined_button.dart';
import 'package:faculty_load/widgets/title_text.dart';
import 'package:faculty_load/widgets/top_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    String title = "Register";
    String imgPath = "assets/images/faculty_load.png";
    final SignUpController controller = Get.find();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
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
                    controller: controller.nameController,
                    hintText: "name",
                    keyboardType: TextInputType.name,
                    width: width * 0.8,
                    icon: const Icon(FontAwesomeIcons.user, size: 17),
                  ),
                  SizedBox(
                    height: Responsive.verticalSize(15),
                  ),
                  MyTextField(
                    controller: controller.emailController,
                    hintText: "email address",
                    keyboardType: TextInputType.emailAddress,
                    width: width * 0.8,
                    icon: const Icon(FontAwesomeIcons.at, size: 17),
                  ),
                  SizedBox(
                    height: Responsive.verticalSize(15),
                  ),
                  MyTextField(
                    hintText: "password",
                    controller: controller.passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    width: width * 0.8,
                    icon: const Icon(Icons.lock_outline_rounded, size: 19),
                  ),
                  SizedBox(
                    height: Responsive.verticalSize(15),
                  ),
                  MyTextField(
                    controller: controller.academicRankController,
                    hintText: "academic rank",
                    keyboardType: TextInputType.name,
                    width: width * 0.8,
                    icon: const Icon(FontAwesomeIcons.rankingStar, size: 17),
                  ),
                  SizedBox(
                    height: Responsive.verticalSize(15),
                  ),
                  MyTextField(
                    controller: controller.contactController,
                    hintText: "contact no.",
                    keyboardType: TextInputType.name,
                    width: width * 0.8,
                    icon: const Icon(FontAwesomeIcons.phone, size: 17),
                  ),
                  SizedBox(
                    height: Responsive.verticalSize(25),
                  ),
                  GetBuilder<SignUpController>(builder: (cont) {
                    return MyButton(
                      showCircularBar: cont.isLoading.value,
                      onTap: () => cont.register(),
                      text: "Register",
                    );
                  }),
                  SizedBox(
                    height: Responsive.verticalSize(15),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.login),
                        child: Text(
                          "Login",
                          style: GoogleFonts.poppins(color: mainColor),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: Responsive.verticalSize(15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
