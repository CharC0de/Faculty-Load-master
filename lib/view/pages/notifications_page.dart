// ignore_for_file: unnecessary_const, prefer_const_literals_to_create_immutables, prefer_const_constructors, unused_field

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/helper/modal.dart';
import 'package:faculty_load/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Stateful widget for the NotificationsPage
class NotificationsPage extends StatefulWidget {
  final String uid; // User ID
  final String role; // User role

  NotificationsPage({required this.uid, required this.role});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

// State class for NotificationsPage
class _NotificationsPageState extends State<NotificationsPage> {
  // FirestoreHelper instance for interacting with Firestore
  FirestoreHelper fh = FirestoreHelper();
  // User data model instance
  UserData _userData = UserData(name: '', email: '', role: '', type: '');
  // TextEditingController for search and school year inputs
  TextEditingController search = TextEditingController();
  TextEditingController school_year = TextEditingController();
  // Default semester selection
  String selectedsemester = '1st Semester';

  // Called when the widget is first created
  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data from Firestore
    search.addListener(updateSearch); // Listen for search input changes
  }

  // Loads user data from Firestore
  Future<void> _loadUserData() async {
    var snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();

    // If the user data exists, update the user data state
    if (snapshot.exists) {
      setState(() {
        _userData = UserData.fromMap(snapshot.data()!);
      });
    }
  }

  // Function for adding user (currently not used)
  void _handleAdd() {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddUserPage(uid: widget.uid)));
  }

  // Function for deleting a user from Firestore
  Future _handleDelete(String userId) async {
    try {
      await fh.deleteItem(userId, 'users');
    } catch (e) {
      print('Error deleting user: $e'); // Catch and log any errors
    }
  }

  // Updates the search filter (called whenever search text changes)
  void updateSearch() {
    setState(() {}); // Triggers a rebuild of the widget
  }

  // Saves schedule data and updates Firestore
  Future<void> _savScheduleData(docId) async {
    // Update schedule in Firestore
    fh.updateItem(docId, {"school_year": school_year.text, "semester": selectedsemester}, "schedules");
    // Clear the inputs after saving
    selectedsemester = "";
    school_year.text = "";
    // Show a confirmation message
    Modal().snack(context, message: "Schedule updated successfully!");
  }

  // Builds the UI for the Notifications page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'), // Title of the AppBar
        backgroundColor: mainColor, // Background color for the AppBar
        foregroundColor: Colors.white, // Text color for the AppBar
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fh.streamWithAttributes('notifications', {"receiver": widget.uid}), // Stream of notifications for the user
              builder: (context, snapshot) {
                // Show a loading indicator while waiting for the data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}')); // Show error message if there's an error
                } else {
                  var schedulesLists = snapshot.data!.docs;

                  // Reverse the list to display the latest notifications first
                  var reversedSchedules = schedulesLists.reversed.toList();

                  inspect(reversedSchedules); // Inspect the reversed schedule list (for debugging)

                  return ListView.builder(
                    itemCount: reversedSchedules.length, // Number of items in the list
                    itemBuilder: (context, index) {
                      final scheduleData = reversedSchedules[index].data() as Map<String, dynamic>;
                      final scheduleId = reversedSchedules[index].id;
                      scheduleData['id'] = scheduleId; // Add the document ID to the schedule data
                      final title = scheduleData['title'] ?? ''; // Get title
                      final message = scheduleData['message'] ?? ''; // Get message

                      // Display notification as a ListTile
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.5),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: ListTile(
                          subtitle: Text("$message"), // Display message
                          title: GestureDetector(
                            onTap: () {}, // Action when the notification title is tapped (currently does nothing)
                            child: Text('$title'), // Display title
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
