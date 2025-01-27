// ignore_for_file: unnecessary_const, prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/helper/fstl_generation.dart';
import 'package:faculty_load/helper/modal.dart';
import 'package:faculty_load/models/user_data.dart';
import 'package:faculty_load/view/pages/schedules/add_schedule.dart';
import 'package:faculty_load/view/pages/schedules/preview_all_schedule.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class SchedulesPage extends StatefulWidget {
  final String uid;
  final String role;

  // Constructor accepting user id (uid) and user role
  SchedulesPage({required this.uid, required this.role});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  FirestoreHelper fh = FirestoreHelper(); // Helper class to interact with Firestore
  UserData _userData = UserData(name: '', email: '', role: '', type: ''); // Holds user data
  TextEditingController search = TextEditingController(); // Controller for search input
  TextEditingController school_year = TextEditingController(); // Controller for school year input
  String selectedsemester = '1st Semester'; // Default selected semester

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the page is initialized
    search.addListener(updateSearch); // Add listener to the search text field
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    var snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();

    if (snapshot.exists) {
      setState(() {
        _userData = UserData.fromMap(snapshot.data()!); // Update user data
      });
    }
  }

  // Function for handling user addition (currently unused)
  void _handleAdd() {
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AddUserPage(uid: widget.uid)));
  }

  // Delete a user item from Firestore
  Future _handleDelete(String userId) async {
    try {
      await fh.deleteItem(userId, 'users'); // Delete user from Firestore
    } catch (e) {
      print('Error deleting user: $e'); // Catch and print error
    }
  }

  // Updates the search results based on the input in the search field
  void updateSearch() {
    setState(() {});
  }

  // Save the schedule data and update Firestore
  Future<void> _savScheduleData(docId) async {
    fh.updateItem(docId, {"school_year": school_year.text, "semester": selectedsemester}, "schedules");
    selectedsemester = ""; // Reset selected semester
    school_year.text = ""; // Reset school year input
    Modal().snack(context, message: "Schedule updated successfully!"); // Show confirmation message
  }

  // Builds the UI for the Schedules page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedules'),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        actions: [
          // Show add schedule button for non-admin users
          (_userData.role != "admin")
              ? GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddSchedulePage(
                          uid: widget.uid,
                          role: _userData.role,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: Icon(
                      Icons.add,
                    ),
                  ),
                )
              : SizedBox() // If admin, no add button
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fh.streamWithAttributes('schedules', (_userData.role == "admin") ? {} : {'uid': widget.uid}),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // Show loading indicator
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}')); // Show error message
                } else {
                  var schedulesLists = snapshot.data!.docs; // Get schedule documents from Firestore

                  return ListView.builder(
                    itemCount: schedulesLists.length, // Display list of schedules
                    itemBuilder: (context, index) {
                      final scheduleData = schedulesLists[index].data() as Map<String, dynamic>;
                      final scheduleId = schedulesLists[index].id; // Get schedule document ID
                      scheduleData['id'] = scheduleId; // Add id to schedule data
                      final school_year = scheduleData['school_year'] ?? '';
                      final semester = scheduleData['semester'] ?? '';
                      final schedule = scheduleData['schedule'] ?? '';
                      final status = scheduleData['status'] ?? false;
                      var subject = scheduleData;
                      subject['schedule'] = jsonDecode(scheduleData['schedule']); // Decode the schedule JSON

                      return GestureDetector(
                        onTap: () {
                          print(scheduleId);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PreviewAllSchedulePage(
                                schedule: schedule,
                                scheduleData:FstlGenHelpers.convertSchedule(schedulesLists[index] as DocumentSnapshot<Object?>),
                                title: '$school_year $semester',
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${subject['school_year']} ${subject['semester']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${subject['name']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Status: ${subject["status"] == false ? "Waiting for chairman's approval.." : "Active"}',
                                ),
                                SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    (_userData.role == "admin")
                                        ? GestureDetector(
                                      onTap: () async {
                                        DateTime now = DateTime.now();
                                        String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
                                        await fh.updateItem(scheduleId, {"status": !status}, "schedules");
                                        await fh.createItem({
                                          "uid": widget.uid,
                                          "receiver": subject['uid'],
                                          "title": "Schedule Status",
                                          "message":
                                          "${subject['school_year']} ${subject['semester']} schedule status has been ${status == false ? 'APPROVED' : 'REVOKED'} at ${formattedDate}."
                                        }, "notifications");
                                        Modal().snack(context,
                                            message: status == false ? "Schedule approved successfully!" : "Approval revoked successfully!");
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            status == false ? Icons.check : Icons.close,
                                            color: mainColor,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text(status == false ? "Approve Status" : "Revoke Approval")
                                        ],
                                      ),
                                    )
                                        : SizedBox(),
                                    (_userData.role == "admin")
                                        ? GestureDetector(
                                      onTap: () async {
                                        bool confirm = await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm Deletion'),
                                            content: Text('Are you sure you want to delete this schedule?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                            false;

                                        if (confirm) {
                                          await fh.deleteItem(scheduleId, 'schedules');
                                          Modal().snack(context, message: 'Schedule deleted successfully!');
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text('Delete'),
                                        ],
                                      ),
                                    )
                                        : SizedBox(),
                                    (widget.uid == subject['uid'])
                                        ? GestureDetector(
                                      onTap: () {
                                        selectedsemester = semester;
                                        school_year.text = school_year;
                                        openModal(context, scheduleId); // Open modal for editing schedule
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: mainColor,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text("Edit")
                                        ],
                                      ),
                                    )
                                        : SizedBox(),
                                  ],
                                ),

                              ],
                            ),
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

  // Open modal for editing schedule
  void openModal(BuildContext context, docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Schedule', textAlign: TextAlign.center),
          content: SizedBox(
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: school_year,
                  decoration: InputDecoration(
                    labelText: 'School Year',
                    hintText: 'e.g., 2024-2025',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                  ),
                  items: ['1st Semester', '2nd Semester']
                      .map((semester) => DropdownMenuItem(
                            value: semester,
                            child: Text(semester),
                          ))
                      .toList(),
                  onChanged: (value) {
                    // Handle semester change
                    setState(() {
                      selectedsemester = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _savScheduleData(docId); // Save updated schedule data
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
