
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/helper/pdf_generator.dart';
import 'package:faculty_load/view/pages/generate_reports_page.dart';
import 'package:faculty_load/view/pages/notifications_page.dart';
import 'package:faculty_load/view/pages/schedules/schedule_page.dart';
import 'package:faculty_load/widgets/top_image.dart';
import 'package:flutter/material.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/helper/modal.dart';
import 'package:faculty_load/models/user_data.dart';
import 'package:faculty_load/view/pages/profile_page.dart';
import 'package:faculty_load/view/pages/users/users_page.dart';
import 'package:get/get.dart';
import 'package:faculty_load/data/api/api.dart';
import 'package:faculty_load/router/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_planner/time_planner.dart';

class Home extends StatefulWidget {
  final User user;

  // Constructor to initialize the Home widget with the logged-in user.
  const Home({super.key, required this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserData _userData = UserData(name: '', email: '', role: '');
  FirestoreHelper fh = FirestoreHelper();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String? qrCodeResult;
  var students = [];

  var id = "";
  var name = "";
  var section = "";
  late DocumentSnapshot selectedSchedule;
  // PDF document instance for extracting text
  List timetableData = [];
  final List<String> weekDays = ["M", "T", "W", "Th", "F", "S", "SU"];
  List<TimePlannerTask> tasks = [];

  // Loads user data from Firestore based on the logged-in user's UID.
  Future<void> _loadUserData() async {
    var snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();

    if (snapshot.exists) {
      setState(() {
        _userData = UserData.fromMap(snapshot.data()!);
      });
    }
  }

  // Converts various data types to double. Handles cases for strings, integers, and doubles.
  double ctd(dynamic value) {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else {
      return 0.0; // Default value for non-convertible types
    }
  }

  @override
  void initState() {
    // Initial setup when the widget is created.
    super.initState();
    _loadUserData(); // Load user details from Firestore.
    _loadSchedule(); // Load schedules for the user.
  }

  // Placeholder for capturing data (future implementation).
  Future capture(id) async {}

  // Displays a modal dialog with student details.
  Future<void> test() async {
    Modal().show(
      context,
      title: "FlutterFire: Student Found",
      message: "Name: $name \nSection: $section",
      func: () async {},
    );
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

    // Fetch schedules from Firestore with specific attributes.
    var schedules = await fh.readItemsWithAttributes("schedules", {
      "uid": widget.user.uid,
      "status": true,
    });

    if (schedules.length > 1) {
      // Logic to find the latest schedule based on school year and semester.
      var ha = schedules[0];
      var hal = [];
      for (var schedule in schedules) {
        var tmp = schedule;
        if (tmp['school_year'] > ha['school_year']) {
          ha = tmp;
          hal.add(ha);
        }
      }

      var hals = [];
      for (var schedule in hal) {
        var tmp = schedule;
        if (tmp['semester'] > ha['semester']) {
          ha = tmp;
          hals.add(ha);
        }
      }

      timetableData = await jsonDecode(hals[0]['schedule']);
      selectedSchedule = hals[0];
    } else if (schedules.length == 1) {
      timetableData.addAll(await jsonDecode(schedules[0]['schedule']));
      timetableData.addAll(await jsonDecode(schedules[0]['suggested_schedule']));
      selectedSchedule = schedules[0];
    }

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
            child: const Text("Faculty Load")),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer(); // Open the drawer
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: darkColor,
                image: DecorationImage(
                  image: AssetImage('assets/images/ustp.jpg'), // Replace with your image asset or network image
                  // fit: BoxFit.cover,
                ),
              ),
              child: Container(), // Keep it empty if you only want to show the image
            ),
            ListTile(
              leading: const Icon(Icons.schedule), // Icon for the profile
              title: Text(_userData.role == "admin" ? 'View Schedules' : 'Upload Schedule'),
              onTap: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SchedulesPage(
                      uid: widget.user.uid,
                      role: _userData.role,
                    ),
                  ),
                );
              },
            ),
            _userData.role == 'admin'
                ? ListTile(
              leading: const Icon(Icons.group_outlined), // Icon for the profile
              title: const Text('Faculties'),
              onTap: () async {
                Get.to(UsersPage(uid: widget.user.uid, role: _userData.role));
              },
            )
                : SizedBox(),
            _userData.role != 'admin'
                ? ListTile(
              leading: const Icon(Icons.file_present_outlined), // Icon for the profile
              title: const Text('Generate Reports'),
              onTap: () async {
                if (tasks.length == 0) {
                  _scaffoldKey.currentState!.openEndDrawer();
                  Modal().snack(context, message: "Can't generate, you dont have any approved schedule!");
                } else {
                  Get.to(GenerateReportsPage(
                    uid: widget.user.uid,
                    role: _userData.role,
                    schedule: selectedSchedule,
                  ));
                }
              },
            )
                : SizedBox(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined), // Icon for the profile
              title: const Text('Notifications'),
              onTap: () async {
                await Get.to(NotificationsPage(uid: widget.user.uid, role: _userData.role));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined), // Icon for the profile
              title: const Text('Profile'),
              onTap: () async {
                await Get.to(ProfilePage(uid: widget.user.uid));
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red), // Icon for the logout, colored red
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                await Get.find<ApiClient>().logout();
                Get.toNamed(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
      body: (_userData.role == "admin")
          ? SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TopImage(
              imgPath: "assets/images/faculty_load.png",
              size: 200,
            ),
            Text(
              "Welcome, ${_userData.name}",
              style: TextStyle(fontSize: 25),
            ),
          ],
        ),
      )
          : TimePlanner(
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