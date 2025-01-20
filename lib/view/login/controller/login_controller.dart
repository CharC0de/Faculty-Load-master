import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/api/api.dart';

class LoginController extends GetxController {
  final ApiClient api;

  LoginController(this.api);

  TextEditingController passwordController = TextEditingController();

  TextEditingController emailController = TextEditingController();

  RxBool isLoading = false.obs;

  FirestoreHelper fh = FirestoreHelper();

  Future<void> login() async {
    isLoading.value = true;
    update();
    try {
      final user = await api.login(emailController.text, passwordController.text);

      if (user != null) {
        var userData = await fh.readItem(user.uid, "users");
        var status = '0';

        try {
          status = userData['status'];
        } catch (error2) {
          print("error: " + error2.toString());
        }

        // if (status == '1') {
        Get.snackbar('Success', 'Logged in successfully!');
        Get.to(Home(user: user));
        // } else {
        //   Get.snackbar('error', 'You are not yet approved by admin please contact your admin!');
        // }
      } else {
        Get.snackbar('error', 'email or password are incorrect');
      }
    } catch (error) {
      print("error: " + error.toString());
      // Handle any errors that occurred while creating the user or updating their profile.
      Get.snackbar('error', 'email or password or name are invalid2');
    }
    isLoading.value = false;
    update();
  }

  Future<void> loginWithGoogle() async {
    try {
      final user = await api.loginWithGoogle();
      if (user != null) {
        Get.snackbar('Success', 'Logged in successfully!');
        Get.to(Home(user: user));
      } else {
        Get.snackbar('error', 'something went wrong');
      }
    } catch (error) {
      // Handle any errors that occurred while creating the user or updating their profile.
      Get.snackbar('error', 'something went wrong');
    }
  }
}
