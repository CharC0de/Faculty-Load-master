// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, non_constant_identifier_names, unused_local_variable, unused_field

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/core/constants/constants.dart';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/view/pages/schedules/edit_schedule.dart';
import 'package:faculty_load/view/pages/schedules/preview_schedule_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:faculty_load/core/constants/colors.dart';
import 'package:faculty_load/helper/modal.dart';
import 'package:faculty_load/models/user_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import "package:flutter/services.dart";
class AddSchedulePage extends StatefulWidget {
  final String uid;
  final String role;

  AddSchedulePage({required this.uid, required this.role});

  @override
  _AddSchedulePageState createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  UserData _userData = UserData(name: '', email: '', role: '', type: '');
  TextEditingController school_year = TextEditingController();
  String selectedsemester = "";
  bool isLoading = false;
  PDFDoc? _pdfDoc;
  var data = {};
  var scheduleData = [];
  var number_of_students = [];
  var details ={};
  var units = {};
  var creditAndLoad ={};
  var suggestedSchedules=[];
  var allSchedules =[];
  var date = '';
  var quasiHours =0;
  final List<String> editableSubjectCodes = [
    "QUASI",
    "CONSULTATION",
    "PREPARATION"
  ];
  FirestoreHelper fh = FirestoreHelper();

  @override
  void initState() {
    super.initState();
    isLoading=false;
    print("######################");
    print(widget.uid);
    print("######################");
    _loadUserData();
    // print();
  }

  Future<void> _loadUserData() async {
    var snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (snapshot.exists) {
      setState(() {
        _userData = UserData.fromMap(snapshot.data()!);
        // name.text = _userData.name;
        // email.text = _userData.email;
      });
    }
  }

  // Async function to save user data and schedule, notify the chairman, and reset the form
  Future<void> _saveUserData() async {
    // Show loading indicator while the data is being saved
    setState(() {
      isLoading = true;
    });

    // Create a new schedule item with user data and save it in the 'schedules' collection
    await fh.createItem(
      {
        "uid": widget.uid, // User ID
        "name": _userData.name, // User name
        "status": false, // Status (false indicates it's a new entry)
        "school_year": school_year.text, // School year input from the text field
        "semester": selectedsemester, // Selected semester
        "schedule": jsonEncode(scheduleData), // Schedule data (encoded to JSON format)
        "suggested_schedule":jsonEncode(suggestedSchedules),
        "details":jsonEncode(details),
        "units":jsonEncode(units),
        "date":date,
        "quasi":quasiHours,
        "totals":jsonEncode(
            {
          "total_subject_credit": data['total_subject_credit'],
          "total_faculty_credit": data['total_faculty_credit'],
          "all_total_students": data['all_total_students'],
              "total_weekly_hours":data['total_weekly_hours'],
        }),
        "credit_and_load":jsonEncode(creditAndLoad)
      },
      "schedules", // Save to the 'schedules' collection
    );

    // Create a notification for the chairman about the new schedule
    await fh.createItem({
      "uid": widget.uid, // User ID
      "receiver": chairman_uid, // Chairman's user ID
      "title": "New Schedule (${_userData.name})", // Notification title
      "message": "${_userData.name}, uploaded new schedule ${school_year.text} $selectedsemester" // Notification message
    }, "notifications"); // Save notification in the 'notifications' collection

    // Reset data and form fields after the schedule is uploaded
    data = {}; // Clear the schedule data
    selectedsemester = ""; // Reset the selected semester
    school_year.text = ""; // Clear the school year input field

    // Hide the loading indicator once the process is complete
    setState(() {
      isLoading = false;
    });

    // Show a success message after the schedule is uploaded
    Modal().snack(context, message: "Schedule uploaded successfully!");
  }

  /// Picks a new PDF document from the device
  Future _pickPDFText() async {

    var filePickerResult = await FilePicker.platform.pickFiles();
    if (filePickerResult != null) {
      int? selectedHours = await _showQuasiHourDialog(context);
      setState(() {
        quasiHours = selectedHours??0;
        isLoading = true;
      });

      _pdfDoc = await PDFDoc.fromPath(filePickerResult.files.single.path!);
      var res = await _pdfDoc!.text;
// Get the file path of the selected file

      try{
        String? filePath = filePickerResult.files.single.path;
        if (filePath == null) {
          throw Exception("Failed to retrieve the file path.");
        }

        Uri apiUrl = Uri.parse("http://139.59.117.201:8000/upload"); // Replace with your Flask API URL

        // Call the upload function

        var result=await uploadPdfToFlaskApi(filePath, apiUrl);
        setState(() {
          data = result;
          scheduleData = List<Map<String,dynamic>>.from(data['schedule']);
          isLoading = false;
        });
      }catch (e){
        debugPrint("Error: $e");
      }
      print("DATA FROM FLASK $data");
      print("DATA FROM FLASK $scheduleData");

      print("################################");
      setState((){
        details=data['details'];
        units =data['units'];
        creditAndLoad = data["credit_and_load"];
      });

      Map<String, double> stringMap = Map<String, double>.from(units);
      allSchedules=[];
      suggestedSchedules = generateSuggestedSchedule(stringMap,List<Map<String,dynamic>>.from(scheduleData),quasiHours );


      setState((){
        allSchedules.addAll(scheduleData);
        allSchedules.addAll(suggestedSchedules);
      });




      //
      // for (var schedule in perLine) {
      //   var res = {};
      //   if (schedule == perLine.last) {
      //     res = extractData(schedule, true);
      //   } else {
      //     res = extractData(schedule, false);
      //   }
      //   data.add(res);
      // }
      //
      // for (var i = 0; i < data.length; i++) {
      //   data[i]["number_of_students"] = number_of_students[i];
      // }

      print("DATA");
      print("$data");
      print("$details");
      print("$units");
      print("$creditAndLoad");
      //print("$date");
      print("test :$suggestedSchedules");
      print("test");

      print("################################");
      print('process completed');

      setState(() {});
    }
  }


// Helper function to convert a string to snake_case
  String toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (match) => '_')
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .toLowerCase();
  }

  Future<int?> _showQuasiHourDialog(BuildContext context) async {
    return await showDialog<int>(
      context: context,
      builder: (context) {
        int? selectedValue = 0; // Default to 0 to avoid null issues
        final textController = TextEditingController();
        const int maxHours = 24; // Define the maximum limit

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Quasi Hours"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int?>(
                    isExpanded: true,
                    value: selectedValue,
                    hint: const Text('Select hours'),
                    items: [
                      const DropdownMenuItem(
                        value: 0,
                        child: Text("No Quasi"),
                      ),
                      ...List.generate(maxHours, (index) => index + 1)
                          .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text("$value ${value == 1 ? 'hour' : 'hours'}"),
                      ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
                        textController.clear(); // Clear input field when selecting dropdown
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("Or enter custom hours:"),
                  TextField(
                    controller: textController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter hours (0-24)',
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0 && parsed <= maxHours) {
                        setState(() => selectedValue = parsed);
                      } else {
                        setState(() => selectedValue = null); // Invalid input clears selection
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedValue != null) {
                      Navigator.pop(context, selectedValue);
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Map<String, String> extractTeacherDetails(String text) {
    Map<String, String> teacherDetails = {};

    try {
      // Normalize text by removing newlines, extra spaces, and unnecessary colons
      text = text.replaceAll('\n', ' ').replaceAll(':', '').replaceAll(RegExp(r'\s+'), ' ');

      // Define regex patterns
      RegExp facultyName = RegExp(r'Faculty Name\s*([\w\s]+?)(?=\s+Rank)', caseSensitive: false);
      RegExp rank = RegExp(r'Rank\s*([\w\s\d]+?)(?=\s+Major Discipline)', caseSensitive: false);
      RegExp majorDiscipline = RegExp(r'Major Discipline\s*([\w\s]+)', caseSensitive: false);
      RegExp designation = RegExp(r'Designation\s*([\w\s\d]+?)(?=\s+Status)', caseSensitive: false);
      RegExp status = RegExp(r'Status\s*([\w\s-]+?)(?=\s+Email Address|$)', caseSensitive: false); // Fixes "Not Found"
      RegExp emailAddress = RegExp(r'Email Address\s*([\w\.\-]+@[a-zA-Z0-9\.\-]+\.[a-zA-Z]+)', caseSensitive: false); // Ensures full email is captured
      RegExp campusCollege = RegExp(r'COLLEGE OF\s*([\w\s]+?)\s*FACULTY LOAD', caseSensitive: false);

      // Extract using regex
      teacherDetails['faculty_name'] = facultyName.firstMatch(text)?.group(1)?.trim() ?? 'Not Found';
      teacherDetails['rank'] = rank.firstMatch(text)?.group(1)?.trim() ?? 'Not Found';
      teacherDetails['major_discipline'] = majorDiscipline.firstMatch(text)?.group(1)?.trim() ?? 'Not Found';
      teacherDetails['designation'] = designation.firstMatch(text)?.group(1)?.trim() ?? 'Not Found';
      teacherDetails['status'] = status.firstMatch(text)?.group(1)?.trim() ?? 'Not Found'; // Now captures "Full-Time"
      teacherDetails['email_address'] = emailAddress.firstMatch(text)?.group(1)?.trim() ?? 'Not Found'; // Ensures full email
      teacherDetails['campus_college'] = campusCollege.firstMatch(text)?.group(1)?.trim() ?? 'Not Found'; // Extracts college name

    } catch (e) {
      print('Error extracting teacher details: $e');
    }

    return teacherDetails;
  }
  Map<String, String> extractFacultyCreditAndLoad(String text) {
    Map<String, String> facultyLoadDetails = {};

    try {
      // Normalize text carefully: Preserve meaningful spacing and dashes
      text = text.replaceAll('\n', ' ') // Replace newlines with space
          .replaceAll(':', '') // Remove colons
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
          .replaceAll(RegExp(r'-\s-+'), ' - '); // Handle long dashes

      // Debugging: Print cleaned text
      print("Cleaned Text: $text");

      // More flexible regex patterns
      RegExp facultyCredit = RegExp(r'FACULTY CREDIT [-\s]+(\d+(\.\d+)?)', caseSensitive: false);
      RegExp designationLoadReleased = RegExp(r'DESIGNATION, LOAD RELEASED [-\s]+(\d+(\.\d+)?)', caseSensitive: false);

      // Extract values
      facultyLoadDetails['faculty_credit'] = facultyCredit.firstMatch(text)?.group(1)?.trim() ?? 'Not Found';
      facultyLoadDetails['designation_load_released'] = designationLoadReleased.firstMatch(text)?.group(1)?.trim() ?? 'Not Found';

    } catch (e) {
      print('Error extracting faculty credit and load released: $e');
    }

    return facultyLoadDetails;
  }
  Map<String, double> extractKeyValues(String extractedText) {
    Map<String, double> result = {};
    try {
      // Normalize text: remove extra spaces and ensure consistent formatting
      extractedText = extractedText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');

      // Define the keys to search for
      Map<String, RegExp> patterns = {
        "number_of_preparation": RegExp(r'Number of Preparation\s*=\s*([\d,.]+)'),
        "average_class_size": RegExp(r'Average Class Size\s*=\s*([\d,.]+)'),
        "average_teaching_units": RegExp(r'Average Teaching Units\s*=\s*([\d,.]+)'),
        "number_of_classes": RegExp(r'Number of Classes\s*=\s*([\d,.]+)'),
        "total_class_hour_per_week": RegExp(r'Total Class Hour per week\s*=\s*([\d,.]+)'),
        "average_class_hour_per_day": RegExp(r'Average Class Hour per day\s*=\s*([\d,.]+)')
      };

      // Extract values using regex
      patterns.forEach((key, pattern) {
        try {
          Match? match = pattern.firstMatch(extractedText);
          if (match != null && match.group(1) != null) {
            result[key] = double.parse(match.group(1)!.replaceAll(',', '.'));
          } else {
            result[key] = 0.0; // Default to 0 if not found
          }
        } catch (e) {
          print('Error parsing value for $key: $e');
          result[key] = 0.0;
        }
      });
    } catch (e) {
      print('Error extracting key values: $e');
    }
    return result;
  }



  List<Map<String, dynamic>> generateSuggestedSchedule(
      Map<String, double> units,
      List<Map<String, dynamic>> existingSchedule,
      int quasiHours) {

    List<String> sortWeekByLeastOccupied(List<Map<String, dynamic>> existingSchedule) {
      // Map to track occupied hours for each day
      final Map<String, int> occupiedHours = {
        'M': 0,
        'T': 0,
        'W': 0,
        'Th': 0,
        'F': 0,
        'S': 0,
      };

      // Helper function to convert time to 24-hour format
      int convertTo24Hour(String time, String daytime) {
        final hour = int.parse(time.split(':')[0]);
        if (daytime == 'PM' && hour != 12) return hour + 12;
        if (daytime == 'AM' && hour == 12) return 0;
        return hour;
      }

      // Accumulate occupied hours for each day from the existing schedule
      for (var item in existingSchedule) {
        for (var slot in item['schedule']) {
          final day = slot['day'];
          final start = convertTo24Hour(slot['time_start'], slot['time_start_daytime']);
          final end = convertTo24Hour(slot['time_end'], slot['time_end_daytime']);

          // Use a default value of 0 if the day is not already initialized
          occupiedHours[day] = (occupiedHours[day] ?? 0) + (end - start);
        }
      }

      // Sort the days by their occupied hours in ascending order
      return occupiedHours.keys.toList()
        ..sort((a, b) => (occupiedHours[a] ?? 0).compareTo(occupiedHours[b] ?? 0));
    }
    // Define start and end hours
    final int startHour = 7; // Earliest available hour
    final int endHour = 21; // Latest available hour

    // Convert AM/PM time to 24-hour format for easier calculations
    int convertTo24Hour(String time, String daytime) {
      final hour = int.parse(time.split(':')[0]);
      if (daytime == 'PM' && hour != 12) {
        return hour + 12; // Add 12 for PM times, except for 12 PM
      }
      if (daytime == 'AM' && hour == 12) {
        return 0; // Convert 12 AM to 0 (midnight)
      }
      return hour; // Return as-is for other cases
    }

    // Extract existing schedules to determine unavailable times
    Map<String, List<Map<String, dynamic>>> occupiedSlots = {};
    for (var item in existingSchedule) {
      for (var slot in item['schedule']) {
        final day = slot['day'];
        final startTime = convertTo24Hour(slot['time_start'], slot['time_start_daytime']);
        final endTime = convertTo24Hour(slot['time_end'], slot['time_end_daytime']);

        if (!occupiedSlots.containsKey(day)) {
          occupiedSlots[day] = [];
        }
        occupiedSlots[day]!.add({'start': startTime, 'end': endTime});
      }
    }

    // Helper: Check if a time slot is available
    bool isSlotAvailable(String day, int startHour, int duration) {
      int endHour = startHour + duration;
      if (endHour > 21) return false; // Exceeds allowed daily end time

      for (var slot in occupiedSlots[day] ?? []) {
        if (startHour < slot['end'] && endHour > slot['start']) {
          return false; // Overlaps with an existing slot
        }
      }
      return true;
    }
    List<Map<String, dynamic>> preparationSchedules = [];
    double preparationHoursNeeded = units['number_of_preparation']! * 2;
    for (var day in sortWeekByLeastOccupied([...existingSchedule,])) {
      if (preparationHoursNeeded <= 0) break;

      for (int hour = startHour; hour <= endHour - 2; hour++) {
        if (isSlotAvailable(day, hour, 2)) {
          preparationSchedules.add({
            'day': day,
            'time_start': '${hour > 12 ? hour - 12 : hour}:00',
            'time_start_daytime': hour >= 12 ? 'PM' : 'AM',
            'time_end': '${(hour + 2) > 12 ? (hour + 2) - 12 : (hour + 2)}:00',
            'time_end_daytime': (hour + 2) >= 12 ? 'PM' : 'AM',
          });
          occupiedSlots[day] ??= [];
          occupiedSlots[day]!.add({'start': hour, 'end': hour + 2});
          preparationHoursNeeded -= 2;
          break; // Limit to one preparation slot per day
        }
      }
    }
    Map<String,dynamic> preparation ={
      'days': '',
      'room': '',
      'schedule': preparationSchedules,
      'section': '',
      'subject': 'Preparation',
      'subject_code': 'PREPARATION',
    };
    // Find available slots for consultation (6 hours/week, 2 hours/day)
    List<Map<String, dynamic>> consultationSchedules = [];
    int consultationHoursNeeded = 6;
    for (var day in sortWeekByLeastOccupied([...existingSchedule,preparation])) {
      if (consultationHoursNeeded <= 0) break;

      for (int hour = startHour; hour <= endHour - 2; hour++) {
        if (isSlotAvailable(day, hour, 2)) {
          consultationSchedules.add({
            'day': day,
            'time_start': '${hour > 12 ? hour - 12 : hour}:00',
            'time_start_daytime': hour >= 12 ? 'PM' : 'AM',
            'time_end': '${(hour + 2) > 12 ? (hour + 2) - 12 : (hour + 2)}:00',
            'time_end_daytime': (hour + 2) >= 12 ? 'PM' : 'AM',
          });
          occupiedSlots[day] ??= [];
          occupiedSlots[day]!.add({'start': hour, 'end': hour + 2});
          consultationHoursNeeded -= 2;
          break; // Limit to one consultation slot per day
        }
      }
    }


    // Find available slots for preparation (units["number_of_preparation"] * 2 hours)


    // Find available slots for quasi hours (quasiHours * 2 hours)
    Map<String,dynamic>consultation=  {
      'days': '',
    'room': 'ONLINE',
    'schedule': consultationSchedules,
    'section': '',
    'subject': 'Consultation',
    'subject_code': 'CONSULTATION',
  };
    List<Map<String, dynamic>> quasiSchedules = [];
    if (quasiHours > 0) {
      int quasiHoursNeeded = quasiHours;
      for (var day in sortWeekByLeastOccupied([...existingSchedule,preparation,consultation])) {
        if (quasiHoursNeeded <= 0) break;

        for (int hour = startHour; hour <= endHour - 1; hour++) {
          int slotDuration = quasiHoursNeeded >= 2 ? 2 : 1; // Adjust slot duration dynamically
          if (isSlotAvailable(day, hour, slotDuration)) {
            quasiSchedules.add({
              'day': day,
              'time_start': '${hour > 12 ? hour - 12 : hour}:00',
              'time_start_daytime': hour >= 12 ? 'PM' : 'AM',
              'time_end': '${(hour + slotDuration) > 12 ? (hour + slotDuration) - 12 : (hour + slotDuration)}:00',
              'time_end_daytime': (hour + slotDuration) >= 12 ? 'PM' : 'AM',
            });
            occupiedSlots[day] ??= [];
            occupiedSlots[day]!.add({'start': hour, 'end': hour + slotDuration});
            quasiHoursNeeded -= slotDuration; // Deduct the allocated hours
            break; // Limit to one quasi slot per day
          }
        }
      }
    }


    // Final output
    List<Map<String, dynamic>> schedules = [
      preparation,
      consultation
    ];

    if (quasiHours > 0) {
      schedules.add({
        'days': '',
        'room': '',
        'schedule': quasiSchedules,
        'section': '',
        'subject': 'Quasi',
        'subject_code': 'QUASI',
      });
    }

    return schedules;
  }
  Map<String, int> convertMapToInt(Map<String, String> inputMap) {
    return inputMap.map((key, value) => MapEntry(key, int.parse(value)));
  }


  // Function to extract data from the given text (like subject details, schedule, room, etc.)
  // extractData(String text, bool isLast) {
  //   // Variables to hold extracted data
  //   var subjectCode = ""; // Subject code (e.g. "CS101")
  //   var subject = ""; // Subject name (e.g. "Computer Science")
  //   var section = ""; // Section (e.g. "A")
  //   var room = ""; // Room where the class is held (e.g. "Room 301")
  //   var rawSchedule = ""; // Raw schedule string (e.g. "M/W 10:00 AM - 12:00 PM")
  //   var subjectLastIndex = 0; // Last index of the subject in the string
  //   var lastRelIndex = 0; // Last relevant index of the string for processing
  //   var isFoundSection = 0; // Flag for finding the section
  //   var isFoundSchedule = 0; // Flag for finding the schedule
  //   var isFoundScheduleEnd = 0; // Flag for finding the end of the schedule
  //   var schedule = []; // List to store schedule data
  //   var indexBeforeSched = 0; // Index before the schedule starts
  //   var indexAfterSection = 0; // Index after the section
  //   var rawUnitsHours = ""; // Raw units and hours string (e.g. "3 6")
  //
  //   // Get the subject code from the text (assumed to be the first part)
  //   for (var i = 2; i < text.length; i++) {
  //     if (text[i] == " ") {
  //       subjectCode = text.substring(2, i); // Extract subject code
  //       lastRelIndex = i;
  //       subjectLastIndex = i;
  //       break;
  //     }
  //   }
  //
  //   // Get the subject name
  //   for (var i = lastRelIndex; i < text.length; i++) {
  //     if (section == "" && i < text.length - 2) {
  //       // Check for a valid section in the text
  //       if (isValidSection(text.substring(i, i + 2)) && isFoundSection == 0) {
  //         isFoundSection = i;
  //       }
  //
  //       // Once section is found, extract it
  //       if (isFoundSection != 0 && text[i] == " ") {
  //         section = text.substring(isFoundSection, i);
  //         lastRelIndex = i;
  //         break;
  //       }
  //     }
  //   }
  //
  //   indexAfterSection = lastRelIndex;
  //
  //   // Get the schedule details from the text
  //   for (var i = lastRelIndex; i < text.length; i++) {
  //     if (RegExp(r'^[a-zA-Z]$').hasMatch(text[i]) && isFoundSchedule == 0) {
  //       isFoundSchedule = i;
  //       if (indexBeforeSched == 0) {
  //         indexBeforeSched = i; // Mark the start of the schedule
  //       }
  //     }
  //
  //     // Look for "AM" or "PM" to identify the end of the schedule
  //     if (isFoundSchedule != 0 && i < text.length - 2) {
  //       if (["AM", "PM"].contains(text.substring(i, i + 2))) {
  //         isFoundScheduleEnd = i + 2;
  //       }
  //     }
  //   }
  //
  //   // If this is the last schedule, clean up the extra data (like room)
  //   if (isLast) {
  //     for (var i = text.length - 1; i > lastRelIndex; i--) {
  //       if (text[i] == " ") {
  //         room = text.substring(isFoundScheduleEnd + 1, i).replaceAll(" ", ""); // Extract room
  //         number_of_students.add(text.substring(i + 1, text.length));
  //         break;
  //       }
  //     }
  //   } else {
  //     room = text.substring(isFoundScheduleEnd + 1, text.length); // For non-last schedule, extract room
  //   }
  //
  //   // Extract subject name from the text
  //   subject = text.substring(subjectLastIndex + 1, isFoundSection - 1);
  //   rawUnitsHours = text.substring(indexAfterSection + 1, indexBeforeSched - 1);
  //   rawSchedule = text.substring(isFoundSchedule, isFoundScheduleEnd); // Extract raw schedule string
  //   schedule = extractSchedule(rawSchedule); // Process the raw schedule into structured data
  //
  //   // Prepare a string containing all the days from the schedule
  //   var days = "";
  //   for (var s in schedule) {
  //     days += s['day'] + " "; // Add each day to the days string
  //   }
  //
  //   // Process the raw units and hours to separate lecture and lab details
  //   var rawUnitsHoursArr = rawUnitsHours.split(" ");
  //   var isLectureOnly = rawUnitsHoursArr.length == 2 ? true : false; // Determine if it's lecture only
  //   var lecu = rawUnitsHoursArr[0]; // Lecture units
  //   var lech = isLectureOnly ? rawUnitsHoursArr[1] : rawUnitsHoursArr[2]; // Lecture hours
  //   var labu = !isLectureOnly ? rawUnitsHoursArr[1] : 0; // Lab units (if any)
  //   var labh = !isLectureOnly ? rawUnitsHoursArr[3] : 0; // Lab hours (if any)
  //
  //   // Return the structured data as a map
  //   return {
  //     "subject_code": subjectCode,
  //     "subject": subject,
  //     "section": section,
  //     "lec_units": lecu,
  //     "lec_hours": lech,
  //     "lab_units": labu,
  //     "lab_hours": labh,
  //     "room": room,
  //     "days": days,
  //     "schedule": schedule,
  //   };
  // }

  // Function to extract schedule details from the provided text

  String extractDate(text){
    final dateRegex = RegExp(
      r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b', // Matches dates in formats like MM-DD-YYYY or MM/DD/YYYY
    );
    final matches = dateRegex.allMatches(text);

    // Collect and return dates in MM/DD/YYYY format
    List<String> preservedDates = [];
    for (var match in matches) {
      String date = match.group(0)!;

      // Validate if the detected date is in MM/DD/YYYY format
      try {
        // Attempt parsing as MM/DD/YYYY
        DateTime parsedDate = DateFormat('MM/dd/yyyy').parse(date);
        preservedDates.add(DateFormat('MM/dd/yyyy').format(parsedDate));
      } catch (e) {
        // Skip invalid formats or unmatched patterns
      }
    }
    return preservedDates[0];

  }
  extractSchedule(String text) {
    var schedules = []; // List to store the extracted schedules
    int count = 0; // Counter to track the number of valid schedule entries
    int temp_count = 0; // Temporary counter to track the occurrence of "AM"/"PM"
    int lastRelIndex = 0; // Index to keep track of the last processed position in the text

    // Loop through the text to count the number of schedules
    for (var i = 0; i < text.length - 1; i++) {
      // Check for "AM" or "PM" to identify the start of a time range
      if (["AM", "PM"].contains(text.substring(i, i + 2))) {
        temp_count++;
        // After finding two time points (AM/PM), increment the main count and reset temp_count
        if (temp_count == 2) {
          count++;
          temp_count = 0;
        }
      }
    }

    // Loop through the text to extract each schedule entry
    for (var i = 0; i < count; i++) {
      var day = ""; // Variable to store the day of the schedule (e.g., "M", "T", "W")
      var dayIndex = 0; // Index where the day ends in the text
      var timeStart = 0; // Index for the start time of the schedule
      var timeEnd = 0; // Index for the end time of the schedule

      // Loop through the text to find the day and time information for each schedule entry
      for (var j = lastRelIndex; j < text.length; j++) {
        // Find the day of the week
        if (text[j] == " " && day == "") {
          dayIndex = j;
          day = text.substring(lastRelIndex, j); // Extract the day
        }

        // Once the day is found, look for the start and end times
        if (dayIndex != 0 && j < text.length - 1) {
          // Find the end time when "AM"/"PM" is found after the start time
          if (timeEnd == 0 && timeStart != 0 && ["AM", "PM"].contains(text.substring(j, j + 2))) {
            timeEnd = j;
            lastRelIndex = j + 3; // Update the last relevant index after finding the end time

            // If a valid day is found, add the schedule entry to the list
            if (["M", "T", "W", "Th", "F", "S"].contains(day)) {
              schedules.add({
                "day": day, // Day of the week
                "time_start": text.substring(dayIndex, timeStart).replaceAll(" ", ""), // Start time
                "time_start_daytime": text.substring(timeStart, timeStart + 2).replaceAll(" ", ""), // AM/PM for start time
                "time_end": text.substring(timeStart + 3, timeEnd).replaceAll(" ", ""), // End time
                "time_end_daytime": text.substring(timeEnd, timeEnd + 2).replaceAll(" ", "") // AM/PM for end time
              });
            } else {
              // If the day contains "TH", handle it separately
              if (day.contains("Th")) {
                schedules.add({
                  "day": "Th", // Special case for Thursday (TH)
                  "time_start": text.substring(dayIndex, timeStart).replaceAll(" ", ""),
                  "time_start_daytime": text.substring(timeStart, timeStart + 2).replaceAll(" ", ""),
                  "time_end": text.substring(timeStart + 3, timeEnd).replaceAll(" ", ""),
                  "time_end_daytime": text.substring(timeEnd, timeEnd + 2).replaceAll(" ", "")
                });
                day = day.replaceAll("Th", ""); // Remove "TH" from the day string
              }

              // For all other valid days (M, T, W, F, S), add them to the schedule
              for (var d in ["M", "T", "W", "F", "S"]) {
                if (day.contains(d)) {
                  schedules.add({
                    "day": d, // Each valid day (M, T, W, F, S)
                    "time_start": text.substring(dayIndex, timeStart).replaceAll(" ", ""),
                    "time_start_daytime": text.substring(timeStart, timeStart + 2).replaceAll(" ", ""),
                    "time_end": text.substring(timeStart + 3, timeEnd).replaceAll(" ", ""),
                    "time_end_daytime": text.substring(timeEnd, timeEnd + 2).replaceAll(" ", "")
                  });
                }
              }
            }

            break; // Move to the next schedule once this one is processed
          }

          // Find the start time when "AM"/"PM" is encountered
          if (timeStart == 0 && ["AM", "PM"].contains(text.substring(j, j + 2))) {
            timeStart = j;
          }
        }
      }
    }

    // Return the list of extracted schedules
    return schedules;
  }

  List<Map<String, dynamic>> processScheduleData(String text) {
    List<Map<String, dynamic>> scheduleData = [];

    // Preprocessing: Combine multiline rows and remove unwanted rows
    List<String> rows = text.split('\n');
    List<String> consolidatedRows = [];
    String tempRow = "";

    for (String row in rows) {
      row = row.trim();
      if (row.isEmpty || row.contains("TOTAL") || row.contains("TIME")) continue;

      // Detect rows starting with a number (start of a new entry)
      if (RegExp(r'^\d+\s').hasMatch(row)) {
        if (tempRow.isNotEmpty) {
          // Append the previous row
          consolidatedRows.add(tempRow);
        }
        tempRow = row;
      } else {
        // Append to the current row
        tempRow += " " + row;
      }
    }
    if (tempRow.isNotEmpty) {
      consolidatedRows.add(tempRow); // Append the last entry
    }

    print("Consolidated rows: ${consolidatedRows}");

    // Process each consolidated row
    for (String row in consolidatedRows) {
      print("Processing row: $row");

      // Improved regex pattern to handle varied row formats
      RegExp regExp = RegExp(
          r'(\d+)\s+(\w+)\s+(.+?)\s+(IT\d+\w*)\s+(\d+)\s+(\d+)\s+([A-Z]+\s[0-9:AMP\- ]+)\s+([A-Za-z0-9\/ ]+)\s+([0-9]+)?');
      Match? match = regExp.firstMatch(row);

      if (match == null) {
        print("Skipped row due to unmatched pattern: $row");
        continue;
      }

      // Extract fields using regex groups
      String subjectCode = match.group(2)!;
      String subject = match.group(3)!;
      String section = match.group(4)!;
      String schedule = match.group(7)!;
      String room = match.group(8)!;
      String numberOfStudents = match.group(9) ?? "N/A";

      print("Matched schedule: $schedule");

      // Parse the schedule into individual day/time entries
      List<Map<String, String>> scheduleList = parseSchedule(schedule);

      scheduleData.add({
        "subject_code": subjectCode,
        "subject": subject,
        "section": section,
        "room": room,
        "schedule": scheduleList,
        "number_of_students": numberOfStudents,
      });
    }

    return scheduleData;
  }

  /// Parses schedule strings into structured day/time mappings
  List<Map<String, String>> parseSchedule(String schedule) {
    List<Map<String, String>> scheduleList = [];
    RegExp timePattern = RegExp(r'([A-Z]+)\s+(\d{1,2}:\d{2}\s[AP]M)-(\d{1,2}:\d{2}\s[AP]M)');
    Iterable<Match> matches = timePattern.allMatches(schedule);

    for (Match match in matches) {
      scheduleList.add({
        "day": match.group(1)!,
        "time_start": match.group(2)!,
        "time_end": match.group(3)!,
      });
    }

    return scheduleList;
  }
  Future<Map<String,dynamic>> uploadPdfToFlaskApi(String filePath, Uri apiUrl) async {
    try {
      // Open the file
      File pdfFile = File(filePath);

      if (!await pdfFile.exists()) {
        throw Exception("File does not exist at the given path: $filePath");
      }

      // Create a Multipart Request
      var request = http.MultipartRequest('POST', apiUrl);

      // Attach the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Key name must match the Flask API's expected parameter
          pdfFile.path,
        ),
      );

      // Send the request
      var response = await request.send();

      // Handle the response
      if (response.statusCode == 200) {
        // Parse the response
        var responseBody = await response.stream.bytesToString();

        return jsonDecode(responseBody);
      } else {
        debugPrint("Failed to upload: ${response.statusCode}");
        return {};

      }
    } catch (e) {
      debugPrint("Error uploading PDF: $e");
      return {};

    }
  }




  // Regular expression: first character is digit, second is uppercase letter
  bool isValidSection(String value) {
    return RegExp(r'^[0-9][A-Z]$').hasMatch(value);
  }

  // Function to separate schedules in the given text by identifying and replacing valid patterns
  separateSchedules(String text) {
    var temp_text = text; // Temporary variable to modify the input text
    number_of_students = [];

    // Iterate through each character in the text
    for (var i = 0; i < text.length; i++) {
      // Check if the current position allows checking the next 4 characters (avoiding out-of-bounds)
      if (i < text.length - 5) {
        var startSrch = i; // Starting index for substring
        var endSrch = i + 4; // Ending index for substring (4 characters after start)
        var rawString = text.substring(startSrch, endSrch); // Extract the 4-character substring

        // Check if the substring starts and ends with a space (a potential valid schedule separator)
        var isValid = rawString[0] == " " && rawString.characters.last == " " ? true : false;

        // If valid, check if the middle character is a number (indicating a schedule)
        if (isValid) {
          var isFound = num.tryParse(rawString.substring(2, 3)) != null; // Check if the third character is a number
          // If the pattern is found, replace the substring with a comma to separate schedules
          if (isFound) {
            number_of_students.add(rawString.replaceAll(" ", ""));
            temp_text = temp_text.replaceFirst(rawString, ",");
          }
        }
      }
    }

    // Split the modified text into a list of strings based on the commas and return the list
    return temp_text.split(",");
  }
  void _editSchedule(Map<String, dynamic> subject, int index) async {
    final updatedSubject = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSubjectScreen(
          subject: subject,
          allSubjects: List<Map<String,dynamic>>.from(allSchedules),
          editableSubjectCodes: editableSubjectCodes,
        ),
      ),
    );

    if (updatedSubject != null) {
      setState(() {
        final index = allSchedules
            .indexWhere((s) => s['subject_code'] == subject['subject_code']);
        if (index != -1) {
          allSchedules[index] = updatedSubject;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(
            color: mainColor,
            child: const Center(
              child: SpinKitFadingCube(
                color: Colors.white,
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('New Schedule'),
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              actions: [
                GestureDetector(
                  onTap: () => openModal(context),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: Icon(
                      Icons.save,
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pickPDFText,
                      child: Text('Upload Schedule'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        maximumSize: Size(double.infinity, 50.0), // Max width and fixed height
                        textStyle: TextStyle(
                          fontSize: 16.0, // Text size
                          fontWeight: FontWeight.bold, // Text weight
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: data.isEmpty
                      ? Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: allSchedules.length,
                          itemBuilder: (context, index) {
                            final isEditable = editableSubjectCodes.contains(allSchedules[index]['subject_code']);
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => PreviewSchedulesPage(schedule: jsonEncode(allSchedules[index]))),
                                );
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                tileColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                title: Text(
                                  '${allSchedules[index]['subject_code']} ${allSchedules[index]['days']!=""?"(${allSchedules[index]['days']})":""}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '${allSchedules[index]['subject']}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black54,
                                  ),
                                ),

                                trailing:Icon(
                                  Icons.arrow_forward_ios,
                                  size: 4.0,
                                  color: Colors.black54,


                                ),

                                leading:isEditable?IconButton(icon:Icon(Icons.edit,size: 16.0,
                                  color: Colors.black54,),onPressed:() => _editSchedule(allSchedules[index], index)):null,
                                )
                            );
                          },
                        ),
                )
              ],
            ),
          );
  }

  void openModal(BuildContext context) {
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
                    // Handle change
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
                _saveUserData();
                // Process the input values here
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
