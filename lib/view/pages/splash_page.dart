// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

// Importing required packages
import 'dart:convert';

import 'package:faculty_load/core/constants/colors.dart'; // Custom color constants
import 'package:faculty_load/core/utils/responsive_size.dart'; // Utility for responsive sizing
import 'package:faculty_load/helper/pdf_generator.dart';
import 'package:faculty_load/home.dart';
import 'package:faculty_load/models/user_data.dart';
import 'package:faculty_load/router/app_routes.dart'; // Application routes for navigation
import 'package:faculty_load/view/pages/generate_reports_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Flutter Material package for UI components
import 'package:flutter/widgets.dart';
import 'package:get/get.dart'; // GetX package for state management and navigation
import 'package:lottie/lottie.dart'; // Package for displaying Lottie animations

// SplashPage StatefulWidget: Represents the splash screen displayed on app startup
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

// State class for SplashPage
class _SplashPageState extends State<SplashPage> {
  // Variable to track loading status (currently unused)
  var isLoading = false;

  @override
  void initState() {
    // Initializes the state and calls the loading function
    super.initState();
    loading();
  }

  // Simulates a loading process with a 5-second delay and navigates to the login page
  void loading() async {
    await Future.delayed(
      Duration(seconds: 5), // Simulate a delay (e.g., loading resources)
    );
    Get.toNamed(AppRoutes.login); // Navigate to the login page using GetX
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity, // Makes the container take the full width of the screen
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            // Displays a Lottie animation for the splash screen
            GestureDetector(onTap: () {}, child: Lottie.asset('assets/anim/splash_anim.json', height: 250)),
            SizedBox(
              height: 20, // Adds spacing below the animation
            ),
            // Displays the "Faculty Load" text with custom styling
            RichText(
              text: TextSpan(
                text: "Faculty", // First part of the text
                children: [
                  TextSpan(
                    text: " Load", // Second part of the text with different styling
                    style: TextStyle(
                      color: primaryColor, // Custom primary color
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
                style: TextStyle(
                  color: mainColor, // Custom main color
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: Responsive.verticalSize(50), // Responsive vertical spacing
            ),
          ],
        ),
      ),
    );
  }
}
