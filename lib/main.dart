import 'package:faculty_load/core/utils/initial_bindings.dart'; // Import custom bindings for dependency injection
import 'package:faculty_load/firebase_options.dart'; // Firebase configuration for different platforms
import 'package:faculty_load/router/app_routes.dart'; // Application routes for navigation
import 'package:firebase_core/firebase_core.dart'; // Firebase core library for initialization
import 'package:flutter/material.dart'; // Flutter material package for UI components
import 'package:get/get.dart'; // GetX package for state management and routing
import 'package:firebase_app_check/firebase_app_check.dart'; // Firebase App Check for app integrity

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter bindings are initialized before Firebase setup

  // Initialize Firebase with platform-specific options

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint("${DefaultFirebaseOptions.currentPlatform}");
    debugPrint('Stack trace: $stackTrace');
  }

  // Activate Firebase App Check to enhance app security
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity, // Use Play Integrity for Android
  );

  // Run the main application widget
  runApp(const MyApp());
}

// The main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false, // Disable debug banner
      title: 'Faculty Load', // Application title
      initialRoute: AppRoutes.splash, // Define the initial route to load (splash screen)
      getPages: AppRoutes.pages, // Define the application's page routes
      initialBinding: InitialBindings(), // Bind dependencies when the app starts
    );
  }
}
