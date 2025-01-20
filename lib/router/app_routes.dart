import 'package:faculty_load/view/pages/splash_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:faculty_load/home.dart';
import 'package:faculty_load/view/login/login.dart';
import 'package:faculty_load/view/signup/signup.dart';
import 'package:get/get.dart';
import 'package:faculty_load/models/user_data.dart';

class AppRoutes {
  static String facereco = '/facereco';
  static String home = '/home';
  static String splash = '/splash';

  static String login = '/login';

  static String signup = '/signup';

  static List<GetPage> pages = [
    GetPage(
      name: login,
      page: () => const Login(),
    ),
    GetPage(
      name: splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: signup,
      page: () => const SignUp(),
    ),
  ];
}
