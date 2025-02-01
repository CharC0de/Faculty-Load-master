// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/data/firestore_helper.dart';

import 'package:faculty_load/models/user_data.dart';

import 'package:time_planner/time_planner.dart';

class ViewSchedule extends StatefulWidget {
  //final User user;
  final List<Map<String, dynamic>> allSubjects;

  // Constructor to initialize the Home widget with the logged-in user.
  const ViewSchedule({super.key,required this.allSubjects,});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<ViewSchedule> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserData _userData = UserData(name: '', email: '', role: '');
  FirestoreHelper fh = FirestoreHelper();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String? qrCodeResult;
  var students = [];

  var id = "";
  var name = "";
  var section = "";
  late List<Map<String,dynamic>> selectedSchedule;
  // PDF document instance for extracting text
  List timetableData = [];
  final List<String> weekDays = ["M", "T", "W", "Th", "F", "S", "SU"];
  List<TimePlannerTask> tasks = [];


  @override
  void initState() {
    // Initial setup when the widget is created.
    super.initState();
     // Load user details from Firestore.
    _loadSchedule(); // Load schedules for the user.
  }



  final List<Map<String, Color>> colorPalette = [
    {'background': Colors.red, 'foreground': Colors.white},
    {'background': Colors.pink, 'foreground': Colors.white},
    {'background': Colors.purple, 'foreground': Colors.white},
    {'background': Colors.deepPurple, 'foreground': Colors.white},
    {'background': Colors.indigo, 'foreground': Colors.white},
    {'background': Colors.blue, 'foreground': Colors.white},
    {'background': Colors.lightBlue, 'foreground': Colors.black},
    {'background': Colors.cyan, 'foreground': Colors.black},
    {'background': Colors.teal, 'foreground': Colors.white},
    {'background': Colors.green, 'foreground': Colors.black},
    {'background': Colors.lightGreen, 'foreground': Colors.black},
    {'background': Colors.lime, 'foreground': Colors.black},
    {'background': Colors.yellow, 'foreground': Colors.black},
    {'background': Colors.amber, 'foreground': Colors.black},
    {'background': Colors.orange, 'foreground': Colors.white},
    {'background': Colors.deepOrange, 'foreground': Colors.white},
    {'background': Colors.brown, 'foreground': Colors.white},
    {'background': Colors.grey, 'foreground': Colors.black},
    {'background': Colors.blueGrey, 'foreground': Colors.white},
  ];

  // Loads the schedule for the logged-in user and prepares the timetable data.
  _loadSchedule() async {
    timetableData = [];





      timetableData.addAll(widget.allSubjects);

      selectedSchedule = widget.allSubjects;


    setState(() {});

    // Prepare tasks for the TimePlanner widget.
    var colorCount = 0;
    for (var subject in timetableData) {
      for (var schedule in subject['schedule']) {
        int startHour = int.parse(schedule['time_start'].split(':')[0]);
        int startMinute = int.parse(schedule['time_start'].split(':')[1]);
        int endHour = int.parse(schedule['time_end'].split(':')[0]);
        int endMinute = int.parse(schedule['time_end'].split(':')[1]);

        if (schedule['time_start_daytime'] == 'PM' && startHour != 12) {
          startHour += 12;
        }

        if (schedule['time_end_daytime'] == 'PM' && endHour != 12) {
          endHour += 12;
        }

        int durationMinutes = ((endHour * 60 + endMinute) - (startHour * 60 + startMinute));

        tasks.add(
          TimePlannerTask(
            color: colorPalette[colorCount]['background'],
            dateTime: TimePlannerDateTime(
              day: weekDays.indexOf(schedule['day']),
              hour: startHour,
              minutes: startMinute,
            ),
            minutesDuration: durationMinutes,
            daysDuration: 1,
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${subject['subject']}\n${subject['room']}\n${subject['section']!=""?"(${subject['section']})":""}",
                style: TextStyle(color: colorPalette[colorCount]['foreground'], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );

        colorCount++;

        if (colorCount >= colorPalette.length) {
          colorCount = 0;
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        title: GestureDetector(
            onTap: () {
              // test();
            },
            child: const Text("Preview Schedule")),

      ),

      body: TimePlanner(
        // time will be start at this hour on table
        startHour: 6,
        // time will be end at this hour on table
        endHour: 23,
        currentTimeAnimation: false,
        style: TimePlannerStyle(
          // backgroundColor: primaryColor,
        ),
        // each header is a column and a day
        headers: [
          TimePlannerTitle(
            title: "Monday",
            // titleStyle: TextStyle(color: primaryColor),
          ),
          TimePlannerTitle(
            title: "Tuesday",
          ),
          TimePlannerTitle(
            title: "Wednesday",
          ),
          TimePlannerTitle(
            title: "Thursday",
          ),
          TimePlannerTitle(
            title: "Friday",
          ),
          TimePlannerTitle(
            title: "Saturday",
          ),
          TimePlannerTitle(
            title: "Sunday",
          ),
        ],
        // List of task will be show on the time planner
        tasks: tasks,
      ),
    );
  }
}