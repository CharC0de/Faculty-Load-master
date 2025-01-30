// ignore_for_file: unnecessary_const, prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// PreviewSchedulesPage is a StatefulWidget that displays detailed information about a schedule
class PreviewSchedulesPage extends StatefulWidget {
  final String schedule; // The schedule information passed to the page

  // Constructor to accept the schedule data
  PreviewSchedulesPage({required this.schedule});

  @override
  State<PreviewSchedulesPage> createState() => _PreviewSchedulesPageState();
}

// State class for PreviewSchedulesPage that manages and updates the UI
class _PreviewSchedulesPageState extends State<PreviewSchedulesPage> {
  // Variables to store schedule details
  var subject_code = "";
  var subject = "";
  var section = "";
  var room = "";
  var days = []; // List of days the schedule occurs
  // Map to associate day abbreviations with full day names
  var weekdays = {
    "M": "Monday",
    "T": "Tuesday",
    "W": "Wednesday",
    "Th": "Thursday",
    "F": "Friday",
    "S": "Saturday",
  };

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load schedule data when the page initializes
    print(widget.schedule); // Print the schedule to the console for debugging
  }

  // Function to load and parse the schedule data from the passed JSON string
  Future<void> _loadUserData() async {
    var schedule = await jsonDecode(widget.schedule); // Decode the passed JSON string
    // Extract schedule details from the decoded data
    subject_code = schedule['subject_code'];
    subject = schedule['subject'];
    section = schedule['section'];
    room = schedule['room'];
    days = schedule['schedule']; // List of days and times
    setState(() {}); // Update the UI to reflect the loaded data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$section'), // Display the section name in the app bar
        backgroundColor: mainColor, // Set the app bar background color
        foregroundColor: Colors.white, // Set the app bar text color
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section displaying the subject code, name, and room
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "($subject_code) $subject", // Display subject code and name
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Make text bold
                    fontSize: 18,
                  ),
                ),
                SizedBox(
                  height: 10, // Space between text elements
                ),
                Text("$room"), // Display the room name
              ],
            ),
          ),
          // Display the list of days and schedule times
          Expanded(
            child: ListView.builder(
              itemCount: days.length, // Number of items in the days list
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // When a day item is tapped, navigate to another PreviewSchedulesPage
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PreviewSchedulesPage(schedule: jsonEncode(days[index]))),
                    );
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    tileColor: Colors.grey[200], // Set the background color of the tile
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Rounded corners for the tile
                      side: BorderSide(color: Colors.grey.shade300), // Border color for the tile
                    ),
                    title: Text(
                      "${weekdays[days[index]['day']]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // Make the day text bold
                        fontSize: 16.0,
                        color: Colors.black87, // Set the text color to black
                      ),
                    ),
                    subtitle: Text(
                      "${days[index]['time_start']} ${days[index]['time_start_daytime']} - ${days[index]['time_end']} ${days[index]['time_end_daytime']}",
                      // Display start and end times with AM/PM info
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black54, // Lighter text color for the subtitle
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
