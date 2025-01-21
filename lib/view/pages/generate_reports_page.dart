import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/helper/fstl_generation.dart';
import 'package:faculty_load/helper/modal.dart';
import 'package:faculty_load/helper/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:math';
// The main page for generating reports
class GenerateReportsPage extends StatefulWidget {
  final String uid; // User ID
  final String role; // User's role
  final DocumentSnapshot schedule; // Schedule document from Firestore

  // Constructor for passing necessary data to the page
  GenerateReportsPage({required this.uid, required this.role, required this.schedule});

  @override
  _GenerateReportsPageState createState() => _GenerateReportsPageState();
}

// State class for handling the page's functionality
class _GenerateReportsPageState extends State<GenerateReportsPage> {
  Map<String,dynamic>scheduleData = {};
  @override
  void initState() {
    super.initState();
    // Any initial setup can be added here
    scheduleData=FstlGenHelpers.convertSchedule(widget.schedule);

    askPermission();

  }

  Future<void> askPermission() async {
    // Check if permission is already granted
    if (await Permission.manageExternalStorage.isGranted) {
      print('Storage permission already granted');
      return;
    }

    // Request permission
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      print('Manage External Storage permission granted');
    } else if (status.isPermanentlyDenied) {
      print('Permission permanently denied. Redirecting to app settings...');
      // Redirect the user to the app settings page
      await openAppSettings();
    } else {
      print('Permission denied');
    }
  }

  // Builds the UI for generating reports
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Reports'), // Title of the AppBar
        backgroundColor: mainColor, // Background color of the AppBar
        foregroundColor: Colors.white, // Text color of the AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Padding for the body content
        child: ListView(
          children: <Widget>[
            // First report card: Faculty Schedule & Teaching Load
            ReportTypeCard(
              title: 'Faculty Schedule & Teaching Load',
              icon: Icons.schedule, // Icon for the report
              onTap: () async {
                // Generate and download the Faculty Schedule & Teaching Load report
                askPermission();
                final pdf =await FstlGenHelpers.generatePdf(scheduleData);
                await Printing.layoutPdf(onLayout: (format) async => pdf.save());
                // await generateFSTL(widget.schedule, widget.uid);
                // Display success message using the modal helper
                Modal().snack(context, message: "Faculty Schedule & Teaching Load downloaded successfully!");
              },
            ),
            // SizedBox(height: 3), // Space between the cards
            // // Second report card: Online Class Application Form
            // ReportTypeCard(
            //   title: 'Online Class Application Form',
            //   icon: Icons.file_open_outlined, // Icon for the report
            //   onTap: () async {
            //     // Generate and download the Online Class Application Form report
            //     await generateOCAF(widget.schedule);
            //     // Display success message using the modal helper
            //     Modal().snack(context, message: "Online Class Application Form downloaded successfully!");
            //   },
            // ),
            // SizedBox(height: 3), // Space between the cards
            // // Third report card: Teaching Load Program
            // ReportTypeCard(
            //   title: 'Teaching Load Program',
            //   icon: Icons.event, // Icon for the report
            //   onTap: () async {
            //     // Generate and download the Teaching Load Program report
            //     await generateTLP(widget.schedule);
            //     // Display success message using the modal helper
            //     Modal().snack(context, message: "Teaching Load Program downloaded successfully!");
            //   },
            // ),
            // SizedBox(height: 3), // Space between the cards
            // // Fourth report card: Certificate of Accomplishment of Quasi-Tasks
            // ReportTypeCard(
            //   title: 'Certificate of Accomplishment of Quasi-Tasks',
            //   icon: Icons.file_copy, // Icon for the report
            //   onTap: () async {
            //     // Generate and download the Certificate of Accomplishment of Quasi-Tasks
            //     await generateCAQT(widget.schedule);
            //     // Display success message using the modal helper
            //     Modal().snack(context, message: "Certificate of Accomplishment of Quasi-Tasks downloaded successfully!");
            //   },
            // ),
            // SizedBox(height: 3), // Space between the cards
            // Fourth report card: Certificate of Accomplishment of Quasi-Tasks
            // ReportTypeCard(
            //   title: 'Generate Timetable',
            //   icon: Icons.file_copy, // Icon for the report
            //   onTap: () async {
            //     // Generate and download the Certificate of Accomplishment of Quasi-Tasks
            //     await generateTT(widget.schedule, widget.uid);
            //     // Display success message using the modal helper
            //     Modal().snack(context, message: "Certificate of Accomplishment of Quasi-Tasks downloaded successfully!");
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}

// Custom card widget to display each report type
class ReportTypeCard extends StatelessWidget {
  final String title; // Title of the report
  final IconData icon; // Icon for the report
  final VoidCallback onTap; // Action to perform when the card is tapped

  // Constructor to initialize the properties
  ReportTypeCard({required this.title, required this.icon, required this.onTap});

  // Builds the UI for the report card
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0, // Card shadow elevation
      child: InkWell(
        onTap: onTap, // Action when the card is tapped
        child: ListTile(
          leading: Icon(
            icon, // Icon for the report
            size: 35, // Icon size
            color: Colors.amber.shade600, // Icon color
          ),
          title: Text(
            title, // Title of the report
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Text style for the title
          ),
        ),
      ),
    );
  }
}
