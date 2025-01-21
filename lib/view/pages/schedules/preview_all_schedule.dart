// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, non_constant_identifier_names, unused_local_variable

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/helper/fstl_generation.dart';
import 'package:faculty_load/view/pages/schedules/preview_schedule_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';

import '../../../helper/modal.dart';

// PreviewAllSchedulePage is a StatefulWidget that displays a list of schedules
class PreviewAllSchedulePage extends StatefulWidget {
  final String schedule; // The schedule data passed to the page
  final Map<String,dynamic> scheduleData;
  final String title; // The title of the page, passed to the widget

  // Constructor to accept schedule data and title
  PreviewAllSchedulePage({required this.schedule, required this.title,required this.scheduleData});

  @override
  _PreviewAllSchedulePageState createState() => _PreviewAllSchedulePageState();
}

// State class for PreviewAllSchedulePage that manages and updates the UI
class _PreviewAllSchedulePageState extends State<PreviewAllSchedulePage> {
  // Controller to handle input for the school year (if needed in the future)
  TextEditingController school_year = TextEditingController();
  String selectedsemester = ""; // Selected semester for scheduling (not used in this snippet)
  var data = []; // Holds the schedule data
  FirestoreHelper fh = FirestoreHelper(); // FirestoreHelper instance for Firestore operations

  @override
  void initState() {
    super.initState();
    print("######################");
    print("######################");
    _loadUserData(); // Load user data when the page initializes
    // print(); // Commented out debugging print statement
  }

  // Function to load and decode the schedule data passed from the previous page
  Future<void> _loadUserData() async {
    data = jsonDecode(widget.schedule); // Decode the JSON string into a list of schedules
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Set the app bar title to the passed title
        backgroundColor: mainColor, // Set the app bar background color
        foregroundColor: Colors.white, // Set the text color of the app bar
      ),
      body: Column(
        children: <Widget>[
          // Display either the schedule list or a "No data available" message if no data is found
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'No data available', // Message shown when there is no data
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: data.length, // The number of items in the data list
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Navigate to PreviewSchedulesPage when an item is tapped
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PreviewSchedulesPage(schedule: jsonEncode(data[index]))),
                          );
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding around the list item
                          tileColor: Colors.grey[200], // Background color of the tile
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // Rounded corners for the tile
                            side: BorderSide(color: Colors.grey.shade300), // Border color for the tile
                          ),
                          title: Text(
                            "${data[index]['subject_code']} (${data[index]['section']})", // Display subject code and section
                            style: TextStyle(
                              fontWeight: FontWeight.bold, // Make the subject code and section bold
                              fontSize: 16.0,
                              color: Colors.black87, // Set the text color to a dark shade
                            ),
                          ),
                          subtitle: Text(
                            '${data[index]['subject']} (${data[index]['days']})', // Display subject name and days of the schedule
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.black54, // Lighter text color for the subtitle
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios, // Icon to indicate navigation
                            size: 16.0,
                            color: Colors.black54, // Icon color
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],

      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Padding(padding: EdgeInsets.all(5), child: ElevatedButton(onPressed: () async {


            final pdf =await FstlGenHelpers.generatePdf(widget.scheduleData);
            await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            // await generateFSTL(widget.schedule, widget.uid);
            // Display success message using the modal helper
          }, child:Text('Preview and Print FSTL'))))
        ],
      ),
    );
  }
}
