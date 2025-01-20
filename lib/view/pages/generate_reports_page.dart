import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_load/core/constants/colors.dart';
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
    scheduleData=convertSchedule(widget.schedule);

    askPermission();

  }

  void askPermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      print('storage permission granted');
    } else if (status.isDenied) {
      print('storage permission denied');
    } else if (status.isPermanentlyDenied) {
      // Open app settings for the user to manually grant permissions
      // openAppSettings();
    }

    if (await Permission.manageExternalStorage.request().isGranted) {
      print('Manage External Storage permission granted');
    } else {
      // openAppSettings();
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
                final pdf =await generatePdf(scheduleData);
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
Map<String, dynamic> convertSchedule(DocumentSnapshot<Object?> snapshot) {
  // Extract the data from the snapshot
  final data = snapshot.data() as Map<String, dynamic>?;

  if (data == null) {
    throw Exception('Snapshot data is null');
  }

  // Convert the data to Map<String, Map<String, dynamic>>
  final result = data.map((key, value) {

      return MapEntry(key, value);

  });
  debugPrint("$result");
  return result;
}
String getMergedSchedule(List<Map<String, dynamic>> schedule) {
  // Group entries with the same time ranges
  Map<String, List<String>> groupedSchedules = {};

  for (var entry in schedule) {
    String timeKey =
        "${entry['time_start']} ${entry['time_start_daytime']}-${entry['time_end']} ${entry['time_end_daytime']}";

    if (!groupedSchedules.containsKey(timeKey)) {
      groupedSchedules[timeKey] = [];
    }

    groupedSchedules[timeKey]!.add(entry['day']);
  }

  // Generate the merged schedule string
  return groupedSchedules.entries.map((entry) {
    String days = entry.value.join(); // Concatenate days (e.g., "TTH")
    String timeRange = entry.key; // Keep time range as is
    return "$days $timeRange";
  }).join("\n");
}

Future<pw.Document> generatePdf(Map<String, dynamic> data) async {
  Map<String, dynamic> details = jsonDecode(data["details"]);
  Map<String, dynamic> units = jsonDecode(data["units"]);
  String date = data["date"];
  List<Map<String, dynamic>> suggestedSchedule = List<Map<String, dynamic>>.from(jsonDecode(data["suggested_schedule"]));
  List<Map<String, dynamic>> regularSchedule =  List<Map<String, dynamic>>.from(jsonDecode(data["schedule"]));
  List<Map<String, dynamic>> schedule = [];
  schedule.addAll(regularSchedule);
  schedule.addAll(suggestedSchedule);
  double totalHours = 0;
  totalHours = getTotalHours(schedule);
  double eqTeaching = 0;
  double prepHours =double.parse(units["number_of_preparation"].toString())*2;
  double consultationHours = 6;
  eqTeaching = totalHours - consultationHours - prepHours;
  double totalOverload = units["number_of_preparation"]>1? ((units['total_equivalent_units']-18)<0?units['total_equivalent_units']-18:0):((units['total_equivalent_units']-21)<0?units['total_equivalent_units']-21:0);


  String schoolYear = data['school_year'];
  String semester = data['semester'];

  final logoBytes = await rootBundle.load('assets/ustp_logo.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  // Create a PDF document
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 39),
                  child: pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                ),

                pw.Text(
                  'University of Science and\nTechnology of Southern Philippines',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      font: pw.Font.times()),
                ),
                // Logo
              ],
            ),

            // Title
            pw.Center(
              child: pw.Text(
                'FACULTY SCHEDULE AND TEACHING LOAD',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // Semester and Academic Year

            pw.Padding(
              padding: pw.EdgeInsets.only(left: 135),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Semester : ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '_____${getOrdinalFromString(semester).toUpperCase()}________',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.Text(
                    'Academic Year : ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '__${schoolYear}_______',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Faculty Information Table
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(.5),
                  2: pw.FlexColumnWidth(5),
                  3: pw.FlexColumnWidth(3),
                  4: pw.FlexColumnWidth(.5),
                  5: pw.FlexColumnWidth(5),
                },
                children: [
                  // Row 1
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          'Faculty Name',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          ':',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          details['faculty_name'],
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          'Contact No.',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          ':',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          details['contact_no'],
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Row 2
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          'Academic Rank',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          ':',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          details['academic_rank'],
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          'Email Address',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          ':',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          details['email_address'],
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Row 3
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          'Campus College',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          ':',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          'CITC',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          'Department',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          ':',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: .5),
                        child: pw.Text(
                          details['department'],
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(3),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1.2),
                5: pw.FlexColumnWidth(1.2),
                6: pw.FlexColumnWidth(1.2),
                7: pw.FlexColumnWidth(1.2),
                8: pw.FlexColumnWidth(3),
                9: pw.FlexColumnWidth(3),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    paddedText('No.', bold: true),
                    paddedText('Subject Code', bold: true),
                    paddedText('Descriptive Title', bold: true),
                    paddedText('Section', bold: true),
                    paddedText('Lec. Units', bold: true),
                    paddedText('Lab Units', bold: true),
                    paddedText('Lec. Hours', bold: true),
                    paddedText('Lab Hours', bold: true),
                    paddedText('Schedule', bold: true),
                    paddedText('Building / Room', bold: true),
                    paddedText('No. Of Students', bold: true),
                  ],
                ),
                // Dynamic Rows
                ...List.generate(regularSchedule.length, (index) {
                  final item = regularSchedule[index];
                  return tableRow(
                    index + 1,
                    item["subject_code"]??"",
                    item["subject"]??"",
                    item["section"]??"",
                    item["lec_units"]??"", // Example: Lec Units
                    item["lab_units"]??"", // Example: Lab Units
                    item["lec_hours"]??"", // Example: Lec Hours
                    item["lab_hours"]??"", // Example: Lab Hours
                    getMergedSchedule(List<Map<String, dynamic>>.from(item['schedule'])),
                    item["room"]??"",
                    item["no_of_students"], // Example: No. of students
                  );
                })
              ],
            ),

            pw.SizedBox(height: 2),

            pw.Row(
              children: [
                pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Academic Equivalent Units:',
                                style: pw.TextStyle(fontSize: 6.5),
                              ),
                              pw.Text(
                                '___${units["academic_equivalent_units"]==0?'':units["academic_equivalent_units"]}______',
                                style: pw.TextStyle(
                                    fontSize: 6.5,
                                    decoration: pw.TextDecoration.underline),
                              ),
                            ]),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Administrative/Research Extension Units:',
                                style: pw.TextStyle(fontSize: 6.5),
                              ),
                              pw.Text(
                                '_____${units["administrative/research/extension_units"]==0?'':units["administrative/research/extension_units"]}_____',
                                style: pw.TextStyle(
                                    fontSize: 6.5,
                                    decoration: pw.TextDecoration.underline),
                              ),
                            ]),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Total Equivalent Units:',
                                style: pw.TextStyle(fontSize: 6.5),
                              ),
                              pw.Text(
                                '___${units["total_equivalent_units"]==0?'':units["total_equivalent_units"]}______',
                                style: pw.TextStyle(
                                    fontSize: 6.5,
                                    decoration: pw.TextDecoration.underline),
                              ),
                            ]),
                      ],
                    )),
                pw.Spacer(flex: 3),
                pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      children: [
                        pw.Row(children: [
                          pw.Text(
                            'Total Contact Hours:',
                            style: pw.TextStyle(fontSize: 6.5),
                          ),
                          pw.Text(
                            '___${units["total_contact_hours"]==0?'':units["total_contact_hours"]}______',
                            style: pw.TextStyle(
                                fontSize: 6.5,
                                decoration: pw.TextDecoration.underline),
                          ),
                        ]),
                        pw.Row(children: [
                          pw.Text(
                            'nTotal No. Of Students:',
                            style: pw.TextStyle(fontSize: 6.5),
                          ),
                          pw.Text(
                            '___${units["total_no_of_students"]==0?'':units["total_no_of_students"]}______',
                            style: pw.TextStyle(
                                fontSize: 6.5,
                                decoration: pw.TextDecoration.underline),
                          ),
                        ]),
                        pw.Row(children: [
                          pw.Text(
                            'Number of Preparations:',
                            style: pw.TextStyle(fontSize: 6.5),
                          ),
                          pw.Text(
                            '___${units["number_of_preparation"]==0?'':units["number_of_preparation"]}______',
                            style: pw.TextStyle(
                                fontSize: 6.5,
                                decoration: pw.TextDecoration.underline),
                          ),
                        ]),
                      ],
                    )),
              ],
            ),
            pw.Container(
              height: 2, // Thickness of the line
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 1),

            pw.Center(
              child: pw.Text(
                "TEACHER'S LOAD PROGRAM",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 1), // Reduced spacing
            generateScheduleTable(schedule),

          ],
        );
      },
    ),
  );
  pdf.addPage(
      pw.Page(
          pageFormat: PdfPageFormat.legal,
          margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          build: (pw.Context context) {
            return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,children:
            [
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [

                    pw.Text(
                      'SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 178,
                      padding: pw.EdgeInsets.only(left: 20),
                      child: pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Equivalent teaching (hrs):',
                                        style:
                                        const pw.TextStyle(fontSize: 7.5)),
                                    pw.Text('_____${emptyIfZero(eqTeaching)}____',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Class Prep/Post (hrs):',
                                        style:
                                        const pw.TextStyle(fontSize: 7.5)),
                                    pw.Text('____${emptyIfZero(prepHours)}_____',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Consultation (hrs):',
                                        style:
                                        const pw.TextStyle(fontSize: 7.5)),
                                    pw.Text('____${emptyIfZero(consultationHours)}_____',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Quasi (hrs):',
                                        style:
                                        const pw.TextStyle(fontSize: 7.5)),
                                    pw.Text('_________',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Research and Extension (hrs):',
                                        style:
                                        const pw.TextStyle(fontSize: 7.5)),
                                    pw.Text('_________',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Admin Designation (hrs):',
                                        style:
                                        const pw.TextStyle(fontSize: 7.5)),
                                    pw.Text('_________',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('TOTAL:',
                                        style: pw.TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: pw.FontWeight.bold)),
                                    pw.Text('____${emptyIfZero(totalHours)}_____',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                              pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Text('Total Overload:',
                                        style: pw.TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: pw.FontWeight.bold)),
                                    pw.Text('____${emptyIfZero(totalOverload)}_____',
                                        style: const pw.TextStyle(
                                            decoration:
                                            pw.TextDecoration.underline,
                                            fontSize: 7.5))
                                  ]),
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Container(
                child: pw.Column(
                  children: [

                    pw.Text(
                      'I hereby certify that the above information is true and correct',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.normal,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                '____________${details['faculty_name'].toString().toUpperCase()}_________',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 7.5,fontWeight: pw.FontWeight.bold,decoration: pw.TextDecoration.underline),
                              ),
                              pw.Text(
                                'Name and Signature of Faculty',
                                style: pw.TextStyle(fontSize: 7.5),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                '_______________',
                                style:  pw.TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                    decoration: pw.TextDecoration.underline),
                              ),
                              pw.Text(
                                'Date',
                                style: pw.TextStyle(fontSize: 7.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              // Section with "Recommending Approval" and "Approved"
              pw.Container(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Recommending Approval:',
                            style: pw.TextStyle(
                                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '_____________________',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            'Name and Signature of Department Head',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            '',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '_____________________',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            'Date',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Approved:',
                            style: pw.TextStyle(
                                fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '_____________________',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            'Name and Signature of Dean',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            '',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '__________${date}___________',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            'Date',
                            style: pw.TextStyle(fontSize: 7.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]);
          }
      )
  );

  return pdf; // Return the generated PDF
}
String emptyIfZero(double number)=> number<=0?"":"$number";
double getTotalHours (List<Map<String, dynamic>> schedule){
  final List<String> days = ["M", "T", "W", "TH", "F", "S"];
  Map<String, double> totalHoursPerDay = {
    for (var day in days) day: 0
  };

  for (var entry in schedule) {
    final schedules = entry["schedule"] as List;
    for (var sched in schedules) {
      final day = sched["day"];
      final startTime = parseTime(sched["time_start"], sched["time_start_daytime"]);
      final endTime = parseTime(sched["time_end"], sched["time_end_daytime"]);
      totalHoursPerDay[day] = totalHoursPerDay[day]! +
          endTime.difference(startTime).inMinutes / 30 * 30 / 60; // Half-hour increments
    }


  }
  double totalHours =0;
  for (var day in days){
    totalHours +=totalHoursPerDay[day]??0;
  }
  return totalHours;
}


// Function to generate the weekly schedule table
pw.Table generateScheduleTable(List<Map<String, dynamic>> schedule) {
  final List<String> timeSlots = [
    "7:00 AM - 7:30 AM", "7:30 AM - 8:00 AM", "8:00 AM - 8:30 AM", "8:30 AM - 9:00 AM",
    "9:00 AM - 9:30 AM", "9:30 AM - 10:00 AM", "10:00 AM - 10:30 AM", "10:30 AM - 11:00 AM",
    "11:00 AM - 11:30 AM", "11:30 AM - 12:00 PM", "12:00 PM - 12:30 PM", "12:30 PM - 1:00 PM",
    "1:00 PM - 1:30 PM", "1:30 PM - 2:00 PM", "2:00 PM - 2:30 PM", "2:30 PM - 3:00 PM",
    "3:00 PM - 3:30 PM", "3:30 PM - 4:00 PM", "4:00 PM - 4:30 PM", "4:30 PM - 5:00 PM",
    "5:00 PM - 5:30 PM", "5:30 PM - 6:00 PM", "6:00 PM - 6:30 PM", "6:30 PM - 7:00 PM",
    "7:00 PM - 7:30 PM", "7:30 PM - 8:00 PM", "8:00 PM - 8:30 PM", "8:30 PM - 9:00 PM"
  ];

  final List<String> days = ["M", "T", "W", "TH", "F", "S"];
  final Map<String, String> dayMap = {
    "M": "MON",
    "T": "TUE",
    "W": "WED",
    "TH": "THURS",
    "F": "FRI",
    "S": "SAT"
  };

  final fullDays = days.map((day) => dayMap[day]!).toList();
  final random = Random();
  final subjectColors = <String, PdfColor>{};
  final Set<String> blacklist = <String>{};

  // Assign colors to subjects
  for (var entry in schedule) {
    subjectColors.putIfAbsent(entry["subject"], () {
      final hue = random.nextDouble();
      return pdfColorFromHsl(hue, 0.6, 0.8);
    });
  }

  // Calculate total hours per day
  final Map<String, double> totalHoursPerDay = {
    for (var day in days) day: 0
  };

  for (var entry in schedule) {
    final schedules = entry["schedule"] as List;
    for (var sched in schedules) {
      final day = sched["day"];
      final startTime = parseTime(sched["time_start"], sched["time_start_daytime"]);
      final endTime = parseTime(sched["time_end"], sched["time_end_daytime"]);
      totalHoursPerDay[day] = totalHoursPerDay[day]! +
          endTime.difference(startTime).inMinutes / 30 * 30 / 60; // Half-hour increments
    }
  }

  return pw.Table(
    border: pw.TableBorder.all(),
    columnWidths: {
      0: pw.FlexColumnWidth(1.5),
      for (int i = 1; i <= days.length; i++) i: pw.FlexColumnWidth(0.8),
    },
    children: [
      // Header Row
      pw.TableRow(
        children: [
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text("TIME", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ),
          ...fullDays.map((day) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(day, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          )),
        ],
      ),
      // Time Slot Rows
      ...timeSlots.map((timeSlot) {
        return pw.TableRow(
          children: [
            pw.Container(
              padding: pw.EdgeInsets.only(left: 10),
              child: pw.Text(timeSlot.replaceAll(RegExp(r' AM| PM'), ''), style: pw.TextStyle(fontSize: 8)),
              alignment: pw.Alignment.centerLeft,
            ),
            ...days.map((day) {
              final matchingSubjects = schedule.where((entry) {
                return (entry["schedule"] as List).any((s) {
                  if (s["day"] == day) {
                    final startTime = parseTime(s["time_start"], s["time_start_daytime"]);
                    final endTime = parseTime(s["time_end"], s["time_end_daytime"]);
                    final slotStart = parseTime(
                      timeSlot.split(" - ")[0],
                      timeSlot.contains("AM") ? "AM" : "PM",
                    );
                    return (slotStart.isAtSameMomentAs(startTime) || slotStart.isAfter(startTime)) &&
                        slotStart.isBefore(endTime);
                  }
                  return false;
                });
              }).toList();

              if (matchingSubjects.isNotEmpty) {
                final firstSubject = matchingSubjects.first;
                final subjectKey = "${firstSubject["subject"]}-${day}";
                final subjectColor = subjectColors[firstSubject["subject"]] ?? PdfColors.white;
                if (!blacklist.contains(subjectKey)) {
                  blacklist.add(subjectKey);
                  final info = [
                    firstSubject["subject_code"] ?? 'Unknown',
                    firstSubject["subject"] ?? 'No Subject',
                    firstSubject["section"] ?? '',
                    firstSubject["room"] ?? '',
                  ];

                  return pw.Container(
                    alignment: pw.Alignment.center,
                    padding: pw.EdgeInsets.all(0.5),
                    color: subjectColor,
                    child: pw.Text(
                      info.join("\n"),
                      style: pw.TextStyle(color: PdfColors.black, fontSize: 5),
                      textAlign: pw.TextAlign.center,
                    ),
                  );
                } else {
                  return pw.Container(
                    color: subjectColor,
                    child: pw.Text(
                      "_",
                      style: pw.TextStyle(color: subjectColor, fontSize: 8),
                    ),
                  );
                }
              } else {
                return pw.Container();
              }
            }),
          ],
        );
      }),
      // Total Hours Row
      pw.TableRow(
        children: [
          pw.Container(
            alignment: pw.Alignment.centerLeft,
            padding: pw.EdgeInsets.only(left: 10),
            child: pw.Text("TOTAL HOURS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ),
          ...days.map((day) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text("${totalHoursPerDay[day]}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 8)),
          )),
        ],
      ),
    ],
  );
}




// Function to calculate total subject hours


PdfColor pdfColorFromHsl(double hue, double saturation, double lightness, [double alpha = 1.0]) {
  assert(hue >= 0 && hue <= 1, "Hue must be between 0 and 1");
  assert(saturation >= 0 && saturation <= 1, "Saturation must be between 0 and 1");
  assert(lightness >= 0 && lightness <= 1, "Lightness must be between 0 and 1");
  assert(alpha >= 0 && alpha <= 1, "Alpha must be between 0 and 1");

  double f(double n) {
    final k = (n + hue * 12) % 12;
    final a = saturation * (lightness < 0.5 ? lightness : 1 - lightness);

    // Ensure the range for clamp is valid
    final lowerBound = (k - 3).clamp(0, 12);  // Make sure the lower bound is within range
    final upperBound = (9 - k).clamp(0, 12);  // Make sure the upper bound is within range

    return lightness - a * (lowerBound < upperBound ? lowerBound : upperBound);
  }


  final red = f(0);
  final green = f(8);
  final blue = f(4);

  return PdfColor(red, green, blue, alpha);
}



DateTime parseTime(String time, String period) {
  try {
    // Validate period
    if (period != "AM" && period != "PM") {
      throw FormatException("Invalid period: $period. Must be 'AM' or 'PM'.");
    }
    time=time.replaceAll("AM", "").replaceAll("PM", "").trim();

    // Normalize the time format to HH:mm
    final List<String> parts = time.split(":");
    if (parts.length != 2) {
      throw FormatException("Time should be in HH:mm format.");
    }

    // Normalize single-digit hours to two digits
    String normalizedHour = parts[0].padLeft(2, '0');
    int hours = int.parse(normalizedHour);
    int minutes = int.parse(parts[1]);

    if (hours < 1 || hours > 12 || minutes < 0 || minutes >= 60) {
      throw FormatException("Hours or minutes out of range.");
    }

    // Adjust for AM/PM
    if (period == "AM" && hours == 12) {
      hours = 0; // Midnight case
    } else if (period == "PM" && hours != 12) {
      hours += 12; // Convert PM times except 12 PM
    }

    return DateTime(0, 1, 1, hours, minutes); // Using a dummy date
  } catch (e) {
    throw FormatException("Error parsing time: $e args = time:$time period:$period");
  }
}




pw.Widget paddedText(String text,
    {double fontSize = 7.5,
      pw.TextAlign align = pw.TextAlign.left,
      insets = 3,
      bold = false}) {
  return pw.Padding(
    padding: pw.EdgeInsets.all(double.parse(insets.toString())),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
          fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null),
    ),
  );
}

pw.TableRow tableRow(
    int no,
    String code,
    String title,
    String section,
    String lecUnits,
    String labUnits,
    String lecHours,
    String labHours,
    String schedule,
    String building,
    String students) {
  return pw.TableRow(
    children: [
      paddedText('$no'),
      paddedText(code),
      paddedText(title),
      paddedText(section),
      paddedText(lecUnits),
      paddedText(labUnits),
      paddedText(lecHours),
      paddedText(labHours),
      paddedText(schedule),
      paddedText(building),
      paddedText(students, align: pw.TextAlign.center),
    ],
  );
}

List<pw.TableRow> generateTimeRows() {
  List<String> times = [
    '7:00-7:30',
    '7:30-8:00',
    '8:00-8:30',
    '8:30-9:00',
    '9:00-9:30',
    '9:30-10:00',
    '10:00-10:30',
    '10:30-11:00',
    '11:00-11:30',
    '11:30-12:00',
    '12:00-12:30',
    '12:30-1:00',
    '1:00-1:30',
    '1:30-2:00',
    '2:00-2:30',
    '2:30-3:00',
    '3:00-3:30',
    '3:30-4:00',
    '4:00-4:30',
    '4:30-5:00',
    '5:00-5:30',
    '5:30-6:00',
    '6:00-6:30',
    '6:30-7:00',
    '7:00-7:30',
    '7:30-8:00',
    '8:00-8:30',
    '8:30-9:00',
  ];

  return times.map((time) {
    return pw.TableRow(
      children: [
        pw.Padding(
            padding: pw.EdgeInsets.only(left: 10, top: .5, bottom: .5),
            child: pw.Text(time, style: pw.TextStyle(fontSize: 8))),
        paddedText('', fontSize: 7.5, insets: .5),
        paddedText('', fontSize: 7.5, insets: .5),
        paddedText('', fontSize: 7.5, insets: .5),
        paddedText('', fontSize: 7.5, insets: .5),
        paddedText('', fontSize: 7.5, insets: .5),
        paddedText('', fontSize: 7.5, insets: .5),
      ],
    );
  }).toList();
}

String getOrdinalFromString(String input) {
  RegExp regExp = RegExp(r'\d+(st|nd|rd|th)');
  String? match = regExp.firstMatch(input)?.group(0);
  if (match != null) {
    return match;
  } else {
    throw FormatException('No ordinal number found in the input string');
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
