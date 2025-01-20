// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:faculty_load/data/firestore_helper.dart';
import 'package:faculty_load/helper/file_naming.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

Future<void> savePDF(String fileName, pw.Document pdf) async {
  try {
    // Request storage permissions
    if (await Permission.storage.request().isGranted) {
      // Downloads folder path
      final downloadsPath = "/storage/emulated/0/Download";
      final filePath = '$downloadsPath/$fileName';

      // Write the PDF file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      print('PDF saved to $filePath');
    } else {
      throw Exception('Storage permission not granted.');
    }
  } catch (e) {
    print('Error saving PDF: $e');
  }
}

Future<void> generateReportPDF(schedule) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Center(
        child: pw.Text('Report Content Here'),
      ),
    ),
  );

  await savePDF('Report.pdf', pdf);
}

extractSchedules(schedules) async {
  List tasks = [];
  for (var item in schedules) {
    for (var schedule in item['schedule']) {
      tasks.add({
        "subject_code": item["subject_code"],
        "subject": item["subject"],
        "section": item["section"],
        "room": item["room"],
        "day": schedule["day"],
        "days": schedule["days"],
        "time_start": schedule["time_start"],
        "time_start_daytime": schedule["time_start_daytime"],
        "time_end": schedule["time_end"],
        "time_end_daytime": schedule["time_end_daytime"],
      });
    }
  }

  return tasks;
}

Future<void> generateOCAF(schedule) async {
  final pdf = pw.Document();
  var scheds = await extractSchedules(await jsonDecode(schedule['schedule']));

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Align content to the left
          children: [
            pw.SizedBox(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "Online Class Application Form (OCAF)",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    "(Flexible Work Arrangement)",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, // Align Name, Department, and College to the left
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Name: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['name'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Department: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: "", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  "College: ",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Semester: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['semester'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "School Year: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['school_year'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            // Add Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                // Table Headers
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Course Code & Section",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Course Description",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Day",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Time",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Example Data Row
                ...scheds.map((data) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("${data["subject_code"]!} ${data["section"]!}"),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(data["subject"]!),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(data["day"]!),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("${data["time_start"]!} ${data["time_start_daytime"]!} - ${data["time_end"]!} ${data["time_end_daytime"]!}"),
                      ),
                    ],
                  );
                }).toList(),
                // Add more rows as needed
              ],
            ),
          ],
        ),
      ),
    ),
  );

  await savePDF('OCAF_${filestamp()}.pdf', pdf);
}

Future<void> generateTLP(schedule) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Align content to the left
          children: [
            pw.SizedBox(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "Teacher Load Program",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, // Align Name, Department, and College to the left
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Name: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['name'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Department: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: "", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  "College: ",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Semester: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['semester'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "School Year: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['school_year'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            // Add Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                // Table Headers
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Number of Instructor",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "No. of Teaching Load",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "No. of Minutes per Week",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Remarks",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Example Data Row
                // ...[1, 2, 3, 4].map((data) {
                //   return pw.TableRow(
                //     children: [
                //       pw.Padding(
                //         padding: const pw.EdgeInsets.all(4),
                //         child: pw.Text(" "),
                //       ),
                //       pw.Padding(
                //         padding: const pw.EdgeInsets.all(4),
                //         child: pw.Text(" "),
                //       ),
                //       pw.Padding(
                //         padding: const pw.EdgeInsets.all(4),
                //         child: pw.Text(" "),
                //       ),
                //       pw.Padding(
                //         padding: const pw.EdgeInsets.all(4),
                //         child: pw.Text(" "),
                //       ),
                //     ],
                //   );
                // }).toList(),
                // Add more rows as needed
              ],
            ),
          ],
        ),
      ),
    ),
  );

  await savePDF('TLP_${filestamp()}.pdf', pdf);
}

Future<void> generateCAQT(schedule) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Align content to the left
          children: [
            pw.SizedBox(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "Certificate of Accomplishment of Quasi-Tasks (CAQT)",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 23),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, // Align Name, Department, and College to the left
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Name: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['name'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Department: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: "", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  "College: ",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Month: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: DateFormat('MMMM').format(DateTime.now()), style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Semester: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['semester'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "School Year: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['school_year'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            // Add Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(3),
              },
              children: [
                // Table Headers
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Week",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Quasi-Tasks",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Example Data Row
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("1"),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(""),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("2"),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(""),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("3"),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(""),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("4"),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(""),
                    ),
                  ],
                ),
                // Add more rows as needed
              ],
            ),
          ],
        ),
      ),
    ),
  );

  await savePDF('CAQT_${filestamp()}.pdf', pdf);
}

Future<void> generateFSTL(schedule, uid) async {
  final pdf = pw.Document();
  FirestoreHelper fh = FirestoreHelper();
  var usr = await fh.readItem(uid, "users");
  var scheds = await jsonDecode(schedule['schedule']);

  // Transform the data to include combined schedules
  List combinedSchedule = scheds.map((entry) {
    // Combine all schedules into a single string
    String days = entry['schedule'].map((sched) => sched['day']).join('');
    String timeStart = "${entry['schedule'][0]['time_start']} ${entry['schedule'][0]['time_start_daytime']}";
    String timeEnd = "${entry['schedule'][0]['time_end']} ${entry['schedule'][0]['time_end_daytime']}";
    String schedule = "$days $timeStart-$timeEnd";

    return {
      "subject_code": entry["subject_code"],
      "subject": entry["subject"],
      "section": entry["section"],
      "room": entry["room"],
      "schedule": schedule
    };
  }).toList();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Align content to the left
          children: [
            pw.SizedBox(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "FACULTY SCHEDULE & TEACHING LOAD",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Semester: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['semester'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Academic Year: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    children: [
                      pw.TextSpan(text: schedule['school_year'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, // Align Name, Department, and College to the left
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Faculty Name: ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        children: [
                          pw.TextSpan(text: schedule['name'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Academic Rank: ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        children: [
                          pw.TextSpan(text: usr['academic_rank'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "Campus/College: ",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, // Align Name, Department, and College to the left
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Contact Number: ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        children: [
                          pw.TextSpan(text: usr['contact'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.RichText(
                      text: pw.TextSpan(
                        text: "Email Address: ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        children: [
                          pw.TextSpan(text: usr['email'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "Department: ",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ]),
            pw.SizedBox(height: 20),
            // Add Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(3),
                4: pw.FlexColumnWidth(1),
                5: pw.FlexColumnWidth(1),
                6: pw.FlexColumnWidth(1),
                7: pw.FlexColumnWidth(1),
                8: pw.FlexColumnWidth(1),
                9: pw.FlexColumnWidth(3),
                10: pw.FlexColumnWidth(2),
                11: pw.FlexColumnWidth(1),
              },
              children: [
                // Table Headers
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "No.",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Subject Code",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Descriptive Title",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Section",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Lec Units",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Lab Units",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Lec Hours",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Lab Hours",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Schedule",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "Building / Room",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        "No. of Students",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                ...combinedSchedule.asMap().entries.map((entry) {
                  int index = entry.key + 1; // Start row count from 1
                  var data = entry.value;
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(index.toString(), style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(data['subject_code']!, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(data['subject']!, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(data['section']!, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("3", style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("0", style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("3", style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("0", style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(data['schedule']!, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(data['room']!, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("30", style: pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  );
                }).toList(),
                // Add more rows as needed
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Academic Equivalent Units: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Total Contact Hours: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Administrative/Research/Extension Units: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Total No. of Students: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Total Equivalent Units: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "No. of Preparations: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  await savePDF('FSTL_${filestamp()}.pdf', pdf);
}

Future<void> generateTT(schedule, uid) async {
  final pdf = pw.Document();
  FirestoreHelper fh = FirestoreHelper();
  var usr = await fh.readItem(uid, "users");
  var scheds = await jsonDecode(schedule['schedule']);
  var totalHours = 0;
  num totalUnits = 0;
  var totalStudents = 0;

  // Transform the data to include combined schedules
  List combinedSchedule = scheds.map((entry) {
    // Combine all schedules into a single string
    String days = entry['schedule'].map((sched) => sched['day']).join('');
    String timeStart = "${entry['schedule'][0]['time_start']} ${entry['schedule'][0]['time_start_daytime']}";
    String timeEnd = "${entry['schedule'][0]['time_end']} ${entry['schedule'][0]['time_end_daytime']}";
    String schedule = "$days $timeStart-$timeEnd";

    totalStudents += int.parse(entry["number_of_students"] ?? '0');
    totalHours += (calculateWholeHoursDifference(timeStart, timeEnd) * (entry['schedule'] ?? []).length).toInt();
    totalUnits += int.parse(entry["lec_units"]);

    try {
      totalUnits += int.parse(entry["lab_units"]);
    } catch (e) {
      totalUnits += entry["lab_units"];
    }

    // (int.tryParse()! + int.tryParse(entry["lab_units"])!);
    // print((calculateWholeHoursDifference(timeStart, timeEnd) * (entry['schedule'] ?? []).length).toInt());

    return {
      "subject_code": entry["subject_code"],
      "subject": entry["subject"],
      "section": entry["section"],
      "room": entry["room"],
      "lec_units": entry["lec_units"].toString(),
      "lab_units": entry["lab_units"].toString(),
      "lec_hours": entry["lec_hours"].toString(),
      "lab_hours": entry["lab_hours"].toString(),
      "number_of_students": entry["number_of_students"] ?? '0',
      "schedule": schedule
    };
  }).toList();

  // Load the image asynchronously outside of the widget tree
  Uint8List imageBytes = await loadImage('assets/images/ustp.png'); // Make sure it's Uint8List

  // Add the page with the image and text
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Align content to the left
          children: [
            pw.SizedBox(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(
                    width: double.infinity,
                    child: pw.Row(
                      children: [
                        // Add image from assets
                        pw.Image(
                          pw.MemoryImage(imageBytes), // Use the loaded image bytes as Uint8List
                          width: 100, // Set width as needed
                          height: 100, // Set height as needed
                        ),
                        pw.SizedBox(width: 20), // Space between image and text
                        // Add 2 line text
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('University of Science and', style: pw.TextStyle(fontSize: 17)),
                            pw.Text('Technology of Southern Philippines', style: pw.TextStyle(fontSize: 17)),
                            pw.SizedBox(height: 20),
                            pw.Text(
                              "FACULTY SCHEDULE AND TEACHING LOAD",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17),
                              // textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.SizedBox(width: 10),
                      pw.RichText(
                        text: pw.TextSpan(
                          text: "Semester: ",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          children: [
                            pw.TextSpan(text: schedule['semester'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.RichText(
                        text: pw.TextSpan(
                          text: "Academic Year: ",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          children: [
                            pw.TextSpan(text: schedule['school_year'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start, // Align Name, Department, and College to the left
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              text: "Faculty Name: ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              children: [
                                pw.TextSpan(text: schedule['name'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.RichText(
                            text: pw.TextSpan(
                              text: "Academic Rank: ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              children: [
                                pw.TextSpan(text: usr['academic_rank'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            "Campus/College: ",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start, // Align Name, Department, and College to the left
                        children: [
                          pw.RichText(
                            text: pw.TextSpan(
                              text: "Contact Number: ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              children: [
                                pw.TextSpan(text: usr['contact'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.RichText(
                            text: pw.TextSpan(
                              text: "Email Address: ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              children: [
                                pw.TextSpan(text: usr['email'], style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            "Department: ",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  pw.SizedBox(height: 8),
                  // Add Table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(3),
                      4: pw.FlexColumnWidth(1),
                      5: pw.FlexColumnWidth(1),
                      6: pw.FlexColumnWidth(1),
                      7: pw.FlexColumnWidth(1),
                      8: pw.FlexColumnWidth(1),
                      9: pw.FlexColumnWidth(3),
                      10: pw.FlexColumnWidth(2),
                      11: pw.FlexColumnWidth(1),
                    },
                    children: [
                      // Table Headers
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "No.",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Subject Code",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Descriptive Title",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Section",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Lec Units",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Lab Units",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Lec Hours",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Lab Hours",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Schedule",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "Building / Room",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              "No. of Students",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      ...combinedSchedule.asMap().entries.map((entry) {
                        int index = entry.key + 1; // Start row count from 1
                        var data = entry.value;
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(index.toString(), style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['subject_code']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['subject']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['section']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['lec_units']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['lab_units']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['lec_hours']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['lab_hours']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['schedule']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['room']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(data['number_of_students']!, style: pw.TextStyle(fontSize: 8)),
                            ),
                          ],
                        );
                      }).toList(),
                      // Add more rows as needed
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.RichText(
                  textAlign: pw.TextAlign.start,
                  text: pw.TextSpan(
                    text: "Academic Equivalent Units: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "$totalUnits          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Total Contact Hours: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "$totalHours          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.RichText(
                  textAlign: pw.TextAlign.start,
                  text: pw.TextSpan(
                    text: "Administrative/Research/Extension Units: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "Total No. of Students: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "$totalStudents          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.RichText(
                  textAlign: pw.TextAlign.start,
                  text: pw.TextSpan(
                    text: "Total Equivalent Units: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "$totalUnits          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
                pw.RichText(
                  text: pw.TextSpan(
                    text: "No. of Preparations: ",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                    children: [
                      pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            // pw.SizedBox(
            //   height: 20,
            // ),
            pw.Divider(thickness: 2),
            // pw.SizedBox(
            //   height: 10,
            // ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  "TEACHER'S LOAD PROGRAM",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17),
                  // textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // --------------------------------------------------------------------
  // PAGE 2
  // --------------------------------------------------------------------
  // Sample schedules
  List<Map<String, String>> schedules = [];

  const tasks = [
    {"task": "Quasi", "duration": 2},
    {"task": "Class Preparation/Post Task", "duration": 2},
    {"task": "Consultation Zoom", "duration": 2}
  ];

  const dailyHours = {
    "Monday": ["8:00 AM", "7:00 PM"],
    "Tuesday": ["8:00 AM", "7:00 PM"],
    "Wednesday": ["8:00 AM", "7:00 PM"],
    "Thursday": ["8:00 AM", "7:00 PM"],
    "Friday": ["8:00 AM", "7:00 PM"],
  };

  // print(combinedSchedule);
  for (var combinedSched in combinedSchedule) {
    if (combinedSched['schedule'].contains('TH')) {
      combinedSched['schedule'].replaceAll('TH', '');

      // Split the string into parts
      List<String> parts = combinedSched['schedule'].split(" ");
      parts.removeAt(0);
      String result = parts.join(" ");

      schedules.add({
        "subject": combinedSched['subject_code'],
        "room": combinedSched['room'],
        "day": "Thursday",
        "time_start": result.split("-")[0],
        "time_end": result.split("-")[1],
      });
    }
    if (combinedSched['schedule'].contains('M')) {
      // Split the string into parts
      List<String> parts = combinedSched['schedule'].split(" ");
      parts.removeAt(0);
      String result = parts.join(" ");

      schedules.add({
        "subject": combinedSched['subject_code'],
        "room": combinedSched['room'],
        "day": "Monday",
        "time_start": result.split("-")[0],
        "time_end": result.split("-")[1],
      });
    }
    if (combinedSched['schedule'].contains('T')) {
      // Split the string into parts
      List<String> parts = combinedSched['schedule'].split(" ");
      parts.removeAt(0);
      String result = parts.join(" ");

      schedules.add({
        "subject": combinedSched['subject_code'],
        "room": combinedSched['room'],
        "day": "Tuesday",
        "time_start": result.split("-")[0],
        "time_end": result.split("-")[1],
      });
    }
    if (combinedSched['schedule'].contains('F')) {
      // Split the string into parts
      List<String> parts = combinedSched['schedule'].split(" ");
      parts.removeAt(0);
      String result = parts.join(" ");

      schedules.add({
        "subject": combinedSched['subject_code'],
        "room": combinedSched['room'],
        "day": "Friday",
        "time_start": result.split("-")[0],
        "time_end": result.split("-")[1],
      });
    }
    if (combinedSched['schedule'].contains('S')) {
      // Split the string into parts
      List<String> parts = combinedSched['schedule'].split(" ");
      parts.removeAt(0);
      String result = parts.join(" ");

      schedules.add({
        "subject": combinedSched['subject_code'],
        "room": combinedSched['room'],
        "day": "Saturday",
        "time_start": result.split("-")[0],
        "time_end": result.split("-")[1],
      });
    }
  }

  List<Map<String, String>> updatedSchedule = fillVacantSlots(schedules, tasks, dailyHours);

  // Gap checker
  // for (var element in collection) {}

// Generate a map to track schedules by day
  final scheduleMap = <String, Map<String, dynamic>>{};
  for (var schedule in schedules) {
    String day = schedule['day']!;
    scheduleMap[day] ??= {};
    scheduleMap[day]![schedule['time_start']!] = schedule;
  }

  print(scheduleMap);

// Define the time intervals
  final List<String> timeSlots = [
    "7:00 AM",
    "7:30 AM",
    "8:00 AM",
    "8:30 AM",
    "9:00 AM",
    "9:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "1:00 PM",
    "1:30 PM",
    "2:00 PM",
    "2:30 PM",
    "3:00 PM",
    "3:30 PM",
    "4:00 PM",
    "4:30 PM",
    "5:00 PM",
    "5:30 PM",
    "6:00 PM",
    "6:30 PM",
    "7:00 PM",
    "7:30 PM",
    "8:00 PM",
    "8:30 PM",
    "9:00 PM"
  ];
  DateTime startTime = DateTime(2025, 1, 13, 7, 0); // Start at 7:00 AM
  DateTime endTime = DateTime(2025, 1, 13, 21, 0); // End at 9:00 PM

  // while (startTime.isBefore(endTime)) {
  //   String time = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
  //   timeSlots.add(time);
  //   startTime = startTime.add(Duration(minutes: 30)); // Add 30 minutes
  // }

  // Days of the week
  final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

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

  var i = 0;
  for (var schedule in schedules) {
    schedule['background'] = '#${(colorPalette[i]['background'] ?? Colors.red).value.toRadixString(16)}';
    schedule['foreground'] = (colorPalette[i]['foreground'] == Colors.white) ? '#ffffff' : '#000000';
    i++;
    if (i > 19) {
      i = 0;
    }
  }

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Table(
          // border: pw.TableBorder.all(),
          columnWidths: {
            0: pw.FlexColumnWidth(2),
            ...days.asMap().map((index, _) => MapEntry(index + 1, pw.FlexColumnWidth(2))),
          },
          children: [
            // Table Header
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    "Time Slot",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                ...days.map((day) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        day,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    )),
              ],
            ),
            ...timeSlots.asMap().entries.map((entry) {
              String timeSlot = entry.value;
              List<pw.Widget> rowCells = [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(timeSlot, style: pw.TextStyle(fontSize: 8)),
                ),
              ];

              var count = 0;
              var isCellAdded = false;
              for (String day in days) {
                var schedule = scheduleMap[day]?[timeSlot];
                isCellAdded = false;

                if (schedule != null) {
                  // Skip rendering for the duration of the schedule
                  String subjectRoom = "";
                  if (schedule['subject'] == null) {
                    subjectRoom = "${schedule['task']}";
                  } else {
                    subjectRoom = "${schedule['subject']} (${schedule['room']})";
                  }
                  rowCells.add(
                    pw.Container(
                      color: PdfColor.fromHex(schedule['background']),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(subjectRoom, style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex(schedule['foreground']))),
                      ),
                    ),
                  );
                  isCellAdded = true;
                } else {
                  scheduleMap[day]?.forEach((key, value) {
                    var raw = value['time_start'].substring(0, value['time_start'].length - 3);
                    var raw2 = value['time_end'].substring(0, value['time_end'].length - 3);
                    var raw3 = timeSlot.substring(0, timeSlot.length - 3);
                    var sh = int.parse(raw.split(":")[0]);
                    var sm = int.parse(raw.split(":")[1]);
                    var eh = int.parse(raw2.split(":")[0]);
                    var em = int.parse(raw2.split(":")[1]);
                    var th = int.parse(raw3.split(":")[0]);
                    var tm = int.parse(raw3.split(":")[1]);

                    DateTime startTime = DateTime(2025, 1, 13, value['time_start'].contains("PM") ? sh + 12 : sh, sm); // Start at 7:00 AM
                    DateTime endTime = DateTime(2025, 1, 13, value['time_end'].contains("PM") ? eh + 12 : eh, em); // End at 9:00 PM
                    DateTime timeSlott = DateTime(2025, 1, 13, timeSlot.contains("PM") ? th + 12 : th, tm); // End at 9:00 PM

                    if ((timeSlott.isBefore(endTime) && timeSlott.isAfter(startTime))) {
                      rowCells.add(
                        pw.Container(
                          height: 30,
                          color: PdfColor.fromHex(value['background']),
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text("-", style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex(value['background']))),
                          ),
                        ),
                      );
                      isCellAdded = true;
                    } else {
                      // rowCells.add(
                      //   pw.Padding(
                      //     padding: const pw.EdgeInsets.all(4),
                      //     child: pw.Text("", style: pw.TextStyle(fontSize: 8)),
                      //   ),
                      // );
                    }
                  });
                }

                if (!isCellAdded) {
                  rowCells.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("", style: pw.TextStyle(fontSize: 8)),
                    ),
                  );
                }
                count++;
                if (count > 19) {
                  count = 0;
                }
              }

              return pw.TableRow(children: rowCells);
            }).toList(),
          ],
        ),
      ),
    ),
  );

  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd');
  String formattedDate = formatter.format(now);

  var quasi = 0;
  var classprep = 0;
  var consultation = 0;

  for (var updatedSched in updatedSchedule) {
    if (updatedSched['subject'] == null) {
      if (updatedSched['task'] == "Quasi") {
        quasi += 2;
      }
      if (updatedSched['task'] == "Class Preparation/Post Task") {
        classprep += 2;
      }
      if (updatedSched['task'] == "Consultation Zoom") {
        consultation += 2;
      }
    }
  }

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Align content to the left
          children: [
            pw.SizedBox(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        "SUMMARY",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.SizedBox(
                    height: 10,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 30,
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Equivalent Teaching (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "$totalHours          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Class Prep/Post (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "$classprep          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Consultation (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "$consultation          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Quasi (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "$quasi          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Research and Extension Deload (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Admin Designation Deload (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Total (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              children: [
                                pw.TextSpan(
                                    text: "${quasi + consultation + classprep + totalHours}          ",
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Total Overlload (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  pw.SizedBox(
                    height: 30,
                  ),
                  pw.Text(
                    "I hereby certify that the above information is true and correct",
                    style: pw.TextStyle(fontSize: 12),
                    // textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(
                    height: 20,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 10),
                      pw.Text(
                        "${schedule['name']}",
                        style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        formattedDate,
                        style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 10),
                      pw.Text(
                        "Name and Signature of  Faculty",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Date",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.SizedBox(
                    height: 10,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Recommending Approval:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Approved:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.SizedBox(
                    height: 30,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Name and Signature of Department Head",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Date",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Name and Signature of Dean",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Date",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  await savePDF('FSATL_${filestamp()}.pdf', pdf);
}

Future<Uint8List> loadImage(String imagePath) async {
  // Load image file from assets as a Uint8List (byte array)
  final byteData = await rootBundle.load(imagePath);
  return byteData.buffer.asUint8List(); // Return as Uint8List
}

int calculateWholeHoursDifference(String startTime, String endTime) {
  // Define the date format for parsing
  final DateFormat format = DateFormat("h:mm a");

  // Parse the start and end times
  final DateTime start = format.parse(startTime);
  final DateTime end = format.parse(endTime);

  // Calculate the difference in whole hours
  final Duration difference = end.difference(start);
  return difference.inMinutes ~/ 60; // Integer division to get whole hours
}

Future<void> generateTest() async {
  final pdf = pw.Document();
  // Sample schedules
  final schedules = [
    {
      "subject": "1T412",
      "room": "ICT Room 101",
      "day": "Monday",
      "time_start": "8:00 AM",
      "time_end": "10:00 AM",
    },
    {
      "subject": "1T412",
      "room": "ICT Room 101",
      "day": "Monday",
      "time_start": "11:30 AM",
      "time_end": "2:00 PM",
    },
    {
      "subject": "1T123",
      "room": "ICT Room 102",
      "day": "Tuesday",
      "time_start": "1:00 PM",
      "time_end": "4:00 PM",
    },
    {
      "subject": "1T412",
      "room": "ICT Room 101",
      "day": "Friday",
      "time_start": "1:30 PM",
      "time_end": "4:30 PM",
    },
    {
      "subject": "1T412",
      "room": "ICT Room 101",
      "day": "Friday",
      "time_start": "5:00 PM",
      "time_end": "7:00 PM",
    },
  ];

  // Gap checker
  // for (var element in collection) {}

// Generate a map to track schedules by day
  final scheduleMap = <String, Map<String, dynamic>>{};
  for (var schedule in schedules) {
    String day = schedule['day']!;
    scheduleMap[day] ??= {};
    scheduleMap[day]![schedule['time_start']!] = schedule;
  }

// Define the time intervals
  final List<String> timeSlots = [
    "7:00 AM",
    "7:30 AM",
    "8:00 AM",
    "8:30 AM",
    "9:00 AM",
    "9:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "1:00 PM",
    "1:30 PM",
    "2:00 PM",
    "2:30 PM",
    "3:00 PM",
    "3:30 PM",
    "4:00 PM",
    "4:30 PM",
    "5:00 PM",
    "5:30 PM",
    "6:00 PM",
    "6:30 PM",
    "7:00 PM",
    "7:30 PM",
    "8:00 PM",
    "8:30 PM",
    "9:00 PM"
  ];
  DateTime startTime = DateTime(2025, 1, 13, 7, 0); // Start at 7:00 AM
  DateTime endTime = DateTime(2025, 1, 13, 21, 0); // End at 9:00 PM

  // while (startTime.isBefore(endTime)) {
  //   String time = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
  //   timeSlots.add(time);
  //   startTime = startTime.add(Duration(minutes: 30)); // Add 30 minutes
  // }

  // Days of the week
  final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

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

  var i = 0;
  for (var schedule in schedules) {
    schedule['background'] = '#${(colorPalette[i]['background'] ?? Colors.red).value.toRadixString(16)}';
    schedule['foreground'] = '#${(colorPalette[i]['foreground'] ?? Colors.white).value.toRadixString(16)}';
    i++;
    if (i > 19) {
      i = 0;
    }
  }

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Table(
          // border: pw.TableBorder.all(),
          columnWidths: {
            0: pw.FlexColumnWidth(2),
            ...days.asMap().map((index, _) => MapEntry(index + 1, pw.FlexColumnWidth(2))),
          },
          children: [
            // Table Header
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    "Time Slot",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                ...days.map((day) => pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        day,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    )),
              ],
            ),
            ...timeSlots.asMap().entries.map((entry) {
              String timeSlot = entry.value;
              List<pw.Widget> rowCells = [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(timeSlot, style: pw.TextStyle(fontSize: 8)),
                ),
              ];

              var count = 0;
              var isCellAdded = false;
              for (String day in days) {
                var schedule = scheduleMap[day]?[timeSlot];
                isCellAdded = false;

                if (schedule != null) {
                  // Skip rendering for the duration of the schedule
                  String subjectRoom = "${schedule['subject']} (${schedule['room']})";
                  rowCells.add(
                    pw.Container(
                      color: PdfColor.fromHex(schedule['background']),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(subjectRoom, style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex(schedule['foreground']))),
                      ),
                    ),
                  );
                  isCellAdded = true;
                } else {
                  scheduleMap[day]?.forEach((key, value) {
                    var raw = value['time_start'].substring(0, value['time_start'].length - 3);
                    var raw2 = value['time_end'].substring(0, value['time_end'].length - 3);
                    var raw3 = timeSlot.substring(0, timeSlot.length - 3);
                    var sh = int.parse(raw.split(":")[0]);
                    var sm = int.parse(raw.split(":")[1]);
                    var eh = int.parse(raw2.split(":")[0]);
                    var em = int.parse(raw2.split(":")[1]);
                    var th = int.parse(raw3.split(":")[0]);
                    var tm = int.parse(raw3.split(":")[1]);

                    DateTime startTime = DateTime(2025, 1, 13, value['time_start'].contains("PM") ? sh + 12 : sh, sm); // Start at 7:00 AM
                    DateTime endTime = DateTime(2025, 1, 13, value['time_end'].contains("PM") ? eh + 12 : eh, em); // End at 9:00 PM
                    DateTime timeSlott = DateTime(2025, 1, 13, timeSlot.contains("PM") ? th + 12 : th, tm); // End at 9:00 PM

                    if ((timeSlott.isBefore(endTime) && timeSlott.isAfter(startTime))) {
                      rowCells.add(
                        pw.Container(
                          height: 30,
                          color: PdfColor.fromHex(value['background']),
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text("-", style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex(value['background']))),
                          ),
                        ),
                      );
                      isCellAdded = true;
                    } else {
                      // rowCells.add(
                      //   pw.Padding(
                      //     padding: const pw.EdgeInsets.all(4),
                      //     child: pw.Text("", style: pw.TextStyle(fontSize: 8)),
                      //   ),
                      // );
                    }
                  });
                }

                if (!isCellAdded) {
                  rowCells.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text("", style: pw.TextStyle(fontSize: 8)),
                    ),
                  );
                }
                count++;
                if (count > 19) {
                  count = 0;
                }
              }

              return pw.TableRow(children: rowCells);
            }).toList(),
          ],
        ),
      ),
    ),
  );

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Align content to the left
          children: [
            pw.SizedBox(
              width: double.infinity,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        "SUMMARY",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.SizedBox(
                    height: 10,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 30,
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Equivalent Teaching (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Class Prep/Post (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Consultation (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Quasi (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Research and Extension Deload (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Admin Designation Deload (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Total (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                          pw.RichText(
                            textAlign: pw.TextAlign.start,
                            text: pw.TextSpan(
                              text: "Total Overlload (Hrs): ",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                              children: [
                                pw.TextSpan(text: "          ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  pw.SizedBox(
                    height: 30,
                  ),
                  pw.Text(
                    "I hereby certify that the above information is true and correct",
                    style: pw.TextStyle(fontSize: 12),
                    // textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(
                    height: 20,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 10),
                      pw.Text(
                        "John Doe",
                        style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "10/12/2023",
                        style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 10),
                      pw.Text(
                        "Name and Signature of  Faculty",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Date",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.SizedBox(
                    height: 10,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Recommending Approval:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Approved:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                  pw.SizedBox(
                    height: 30,
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Name and Signature of Department Head",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Date",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Name and Signature of Dean",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        "Date",
                        style: pw.TextStyle(fontSize: 12),
                        // textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  await savePDF('test_${filestamp()}.pdf', pdf);
}

List<Map<String, String>> fillVacantSlots(
    List<Map<String, String>> schedules, List<Map<String, dynamic>> tasks, Map<String, List<String>> dailyHours) {
  final random = Random();
  List<Map<String, String>> result = [...schedules];
  print("I'm here");

  dailyHours.forEach((day, hours) {
    print("I'm here 2");
    final daySchedules = schedules.where((schedule) => schedule["day"] == day).toList();
    daySchedules.sort((a, b) => _timeToMinutes(a["time_start"]!) - _timeToMinutes(b["time_start"]!));

    List<List<String>> vacantSlots = [];
    String currentTime = hours[0];

    for (var schedule in daySchedules) {
      if (_timeToMinutes(schedule["time_start"]!) > _timeToMinutes(currentTime)) {
        vacantSlots.add([currentTime, schedule["time_start"]!]);
      }
      currentTime = schedule["time_end"]!;
    }

    if (_timeToMinutes(hours[1]) > _timeToMinutes(currentTime)) {
      vacantSlots.add([currentTime, hours[1]]);
    }
    print("I'm here 3");
    print(vacantSlots);

    for (var slot in vacantSlots) {
      int vacantDuration = _timeToMinutes(slot[1]) - _timeToMinutes(slot[0]);
      if (vacantDuration >= 120) {
        if (vacantDuration >= 240) {
          // Add 4-hour Consultation task
          result.add({
            "task": "Consultation Zoom",
            "day": day,
            "time_start": slot[0],
            "time_end": _addMinutesToTime(slot[0], 240),
          });
        } else {
          // Add random 2-hour task
          var randomTask = tasks[random.nextInt(2)];
          result.add({
            "task": randomTask["task"],
            "day": day,
            "time_start": slot[0],
            "time_end": _addMinutesToTime(slot[0], randomTask["duration"] * 60),
          });
        }
      }
    }
  });
  print("I'm here 4");

  return result;
}

int _timeToMinutes(String time) {
  final parts = time.split(RegExp(r"[: ]"));
  int hours = int.parse(parts[0]);
  int minutes = int.parse(parts[1]);
  if (parts[2] == "PM" && hours != 12) {
    hours += 12;
  } else if (parts[2] == "AM" && hours == 12) {
    hours = 0;
  }
  return hours * 60 + minutes;
}

String _addMinutesToTime(String time, int minutesToAdd) {
  int totalMinutes = _timeToMinutes(time) + minutesToAdd;
  int hours = (totalMinutes ~/ 60) % 24;
  int minutes = totalMinutes % 60;
  String period = hours >= 12 ? "PM" : "AM";
  if (hours > 12) hours -= 12;
  if (hours == 0) hours = 12;
  return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period";
}
