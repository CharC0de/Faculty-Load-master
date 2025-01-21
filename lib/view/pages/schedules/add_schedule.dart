// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, non_constant_identifier_names, unused_local_variable, unused_field

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/core/constants/constants.dart';
import 'package:faculty_load/data/firestore_helper.dart';
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
  var data = [];
  var number_of_students = [];
  var details ={};
  var units = {};
  var suggestedSchedules=[];
  var allSchedules =[];
  var date = '';
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
        "schedule": jsonEncode(data), // Schedule data (encoded to JSON format)
        "suggested_schedule":jsonEncode(suggestedSchedules),
        "details":jsonEncode(details),
        "units":jsonEncode(units),
        "date":date
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
    data = []; // Clear the schedule data
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
      setState(() {
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

        Uri apiUrl = Uri.parse("https://octopus-app-mb7ca.ondigitalocean.app/upload"); // Replace with your Flask API URL

        // Call the upload function
        git init
        var result=await uploadPdfToFlaskApi(filePath, apiUrl);
        setState(() {
          data = result;           isLoading = false;
        });
      }catch (e){
        debugPrint("Error: $e");
      }

      print("################################");
      getRelevantText(res);

      setState(() {});
    }
  }

  getRelevantText(text) {
    var perLine = text.split("\n");
    var startLine = 0;
    var endLine = 0;

    for (int i = 0; i < perLine.length; i++) {
      if (perLine[i].contains("No. Of Students") && startLine == 0) {
        startLine = i;
      }
      if (perLine[i].contains("TIME MON TUE WED THURS FRI SAT") && endLine == 0) {
        endLine = i;
      }
    }



    perLine = perLine.sublist(startLine + 1, endLine);
    perLine = perLine.join(' ');
    perLine = separateSchedules(perLine);
    setState(() {

      details=extractTeacherDetails(text);
      units =extractKeyValues(text);
      date =extractDate(text);
      //data = processScheduleData(text);
    });
    Map<String, int> stringMap = Map<String, int>.from(units);
    List<Map<String,dynamic>> schedules = List<Map<String,dynamic>>.from(data);
    setState(() {
      allSchedules=[];
      suggestedSchedules = generateSuggestedSchedule(stringMap,schedules );
    });
    setState((){
       allSchedules.addAll(data);
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
    print("$date");
    print("test :$suggestedSchedules");
    print("test");

    print("################################");
  }

// Helper function to convert a string to snake_case
  String toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (match) => '_')
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .toLowerCase();
  }

  Map<String, String> extractTeacherDetails(String text) {
    Map<String, String> teacherDetails = {};

    // Normalize the text to handle inconsistent formatting
    text = text.replaceAll('\n', ' ').replaceAll(':', '');

    // Define possible keys and extract corresponding values
    RegExp facultyName = RegExp(r'Faculty Name\s*([A-Za-z]+\s+[A-Za-z]+\s+[A-Za-z]\.\s+[A-Za-z]+)');
    RegExp academicRank = RegExp(r'Academic Rank\s*([A-Z]+\s+\d)\b');
    RegExp campusCollege = RegExp(r'Campus College\s+([A-Za-z]+)');
    RegExp contactNo = RegExp(r'Contact No\.\s+(\d+)');
    RegExp emailAddress = RegExp(r'Email Address\s+(\S+)');
    RegExp department = RegExp(r'Department\s+([A-Za-z]+)');

    // Extract using regex
    teacherDetails['Faculty Name'] = facultyName.firstMatch(text)?.group(1) ?? 'Not Found';
    teacherDetails['Academic Rank'] = academicRank.firstMatch(text)?.group(1) ?? 'Not Found';
    teacherDetails['Campus College'] = campusCollege.firstMatch(text)?.group(1) ?? 'Not Found';
    teacherDetails['Contact No.'] = contactNo.firstMatch(text)?.group(1) ?? 'Not Found';
    teacherDetails['Email Address'] = emailAddress.firstMatch(text)?.group(1) ?? 'Not Found';
    teacherDetails['Department'] = department.firstMatch(text)?.group(1) ?? 'Not Found';

    // Convert keys to snake_case
    return teacherDetails.map((key, value) => MapEntry(toSnakeCase(key), value));
  }

  Map<String, int> extractKeyValues(String extractedText) {
    // Define the keys to search for
    const keys = [
      "Academic Equivalent Units",
      "Administrative/Research/Extension Units",
      "Total Equivalent Units",
      "Total Contact Hours",
      "Total No. Of Students",
      "Number of Preparation"
    ];

    // Initialize a map to store the results with default values set to 0
    Map<String, int> result = {
      for (var key in keys) key: 0,
    };

    // Process the extracted text line by line
    List<String> lines = extractedText.split('\n');

    for (String line in lines) {
      for (String key in keys) {
        if (line.contains(key)) {
          // Extract the value after the colon
          RegExp valuePattern = RegExp(r':\s*(\d+)?');
          Match? match = valuePattern.firstMatch(line);

          if (match != null && match.group(1) != null) {
            result[key] = int.parse(match.group(1)!);
          }
          break; // No need to check other keys for this line
        }
      }
    }

    // Convert keys to snake_case
    return result.map((key, value) => MapEntry(toSnakeCase(key), value));
  }
  List<Map<String, dynamic>> generateSuggestedSchedule(
      Map<String, int> units,
      List<Map<String, dynamic>> existingSchedule) {
    // Define working hours limits
    final dailyMaxHours = {
      'M': 13,
      'T': 13,
      'W': 11,
      'TH': 13,
      'F': 9,
      'S': 3,
    };

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

    // Find available slots for consultation (6 hours/week, 2 hours/day)
    List<Map<String, dynamic>> preparationSchedules = [];
    int consultationHoursNeeded = 6;
    for (var day in dailyMaxHours.keys) {
      if (consultationHoursNeeded <= 0) break;

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
          consultationHoursNeeded -= 2;
          break; // Limit to one consultation slot per day
        }
      }
    }

    // Find available slots for preparation (units["number_of_preparation"] * 2 hours)
    List<Map<String, dynamic>> consultationSchedules = [];
    int preparationHoursNeeded = units['number_of_preparation']! * 2;
    for (var day in dailyMaxHours.keys) {
      if (preparationHoursNeeded <= 0) break;

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
          preparationHoursNeeded -= 2;
          break; // Limit to one preparation slot per day
        }
      }
    }

    // Final output
    return [
      {
        'days': '',
        'room': 'ONLINE',
        'schedule': consultationSchedules,
        'section': '',
        'subject': 'Consultation',
        'subject_code': 'CONSULTATION',
      },
      {
        'days': '',
        'room': '',
        'schedule': preparationSchedules,
        'section': '',
        'subject': 'Preparation',
        'subject_code': 'PREPARATION',
      },
    ];
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
            if (["M", "T", "W", "TH", "F", "S"].contains(day)) {
              schedules.add({
                "day": day, // Day of the week
                "time_start": text.substring(dayIndex, timeStart).replaceAll(" ", ""), // Start time
                "time_start_daytime": text.substring(timeStart, timeStart + 2).replaceAll(" ", ""), // AM/PM for start time
                "time_end": text.substring(timeStart + 3, timeEnd).replaceAll(" ", ""), // End time
                "time_end_daytime": text.substring(timeEnd, timeEnd + 2).replaceAll(" ", "") // AM/PM for end time
              });
            } else {
              // If the day contains "TH", handle it separately
              if (day.contains("TH")) {
                schedules.add({
                  "day": "TH", // Special case for Thursday (TH)
                  "time_start": text.substring(dayIndex, timeStart).replaceAll(" ", ""),
                  "time_start_daytime": text.substring(timeStart, timeStart + 2).replaceAll(" ", ""),
                  "time_end": text.substring(timeStart + 3, timeEnd).replaceAll(" ", ""),
                  "time_end_daytime": text.substring(timeEnd, timeEnd + 2).replaceAll(" ", "")
                });
                day = day.replaceAll("TH", ""); // Remove "TH" from the day string
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
  Future<List<dynamic>> uploadPdfToFlaskApi(String filePath, Uri apiUrl) async {
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
        return [];

      }
    } catch (e) {
      debugPrint("Error uploading PDF: $e");
      return [];

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
                                  "${allSchedules[index]['subject_code']} ${allSchedules[index]['section']!=""?"(${allSchedules[index]['section']})":""}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '${allSchedules[index]['subject']} ${allSchedules[index]['days']!=""?"(${allSchedules[index]['days']})":""}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black54,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16.0,
                                  color: Colors.black54,
                                ),
                              ),
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
