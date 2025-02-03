import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'dart:math';

class FstlGenHelpers {
  static Map<String, dynamic> convertSchedule(
      DocumentSnapshot<Object?> snapshot) {
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

  static List<String> getMergedSchedule(List<Map<String, dynamic>> schedule) {
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
    groupedSchedules.entries.map((entry) {
      String days = entry.value.join(); // Concatenate days (e.g., "TTH")
      String timeRange = entry.key; // Keep time range as is
      return "$days $timeRange";
    }).join("\n");
    // Generate the merged schedule string
    return [
      groupedSchedules.entries.map((entry) {
        String days = entry.value.join(); // Concatenate days (e.g., "TTH")
        // Keep time range as is
        return days;
      }).join("\n"),
      groupedSchedules.entries.map((entry) {
        // Concatenate days (e.g., "TTH")
        String timeRange = entry.key; // Keep time range as is
        return timeRange;
      }).join("\n")
    ];
  }

  static Future<pw.Document> generatePdf(Map<String, dynamic> data) async {
    print(data);
    Map<String, dynamic> details = jsonDecode(data["details"]);
    Map<String, dynamic> units = jsonDecode(data["units"]);
    Map<String, dynamic> totals = jsonDecode(data['totals']);
    Map<String, dynamic> creditAndLoad = jsonDecode(data['credit_and_load']);
    //String date = data["date"];
    List<Map<String, dynamic>> suggestedSchedule = List<Map<String, dynamic>>.from(jsonDecode(data["suggested_schedule"]));
    List<Map<String, dynamic>> regularSchedule = List<Map<String, dynamic>>.from(jsonDecode(data["schedule"]));
    List<Map<String, dynamic>> schedule = [];
    schedule.addAll(regularSchedule);
    schedule.addAll(suggestedSchedule);
    double totalHours = 0;
    totalHours = getTotalHours(schedule);
    double eqTeaching = 0;
    double prepHours =
        double.parse(units["number_of_preparation"].toString()) * 2;
    double consultationHours = 6;
    double quasi = double.parse(data["quasi"].toString()) ;
    late final double facultyCredit = double.parse(creditAndLoad["faculty_credit"]);
    eqTeaching = totalHours - consultationHours - prepHours;
    double totalOverload = facultyCredit > 1
        ? ((facultyCredit - 18) < 0
        ? facultyCredit - 18
        : 0)
        : ((facultyCredit - 21) < 0
        ? facultyCredit - 21
        : 0);

    String schoolYear = "${data['school_year']}";
    String semester = "${data['semester']}";

    final logoBytes = await rootBundle.load('assets/ustp_logo_1.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Create a PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.legal,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        build: (context)=> [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header Section

              pw.Padding(
                padding: pw.EdgeInsets.all(5),
                child: pw.Container(
                  height: 500,
                  width: 500,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),

              // pw.Text(
              //   'Repub\nTechnology of Southern Philippines',
              //   style: pw.TextStyle(
              //       fontSize: 16,
              //       fontWeight: pw.FontWeight.bold,
              //       font: pw.Font.times()),
              // ),
              // Logo

              pw.Center(
                child: pw.Text(
                    'COLLEGE OF ${details["campus_college"]}\nFACULTY LOAD\n${getOrdinalFromString(semester).toUpperCase()} SEMESTER, SCHOOL YEAR $schoolYear',
                    style: pw.TextStyle(
                      fontSize: 10,
                    ),
                    textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(height: 10),

              // Semester and Academic Year

              // pw.Padding(
              //   padding: pw.EdgeInsets.only(left: 135),
              //   child: pw.Row(
              //     children: [
              //       pw.Text(
              //         'Semester : ',
              //         style: pw.TextStyle(
              //           fontSize: 12,
              //           fontWeight: pw.FontWeight.bold,
              //         ),
              //       ),
              //       pw.Text(
              //         '_____${getOrdinalFromString(semester).toUpperCase()}________',
              //         style: pw.TextStyle(
              //           fontSize: 10,
              //           fontWeight: pw.FontWeight.bold,
              //           decoration: pw.TextDecoration.underline,
              //         ),
              //       ),
              //       pw.Text(
              //         'Academic Year : ',
              //         style: pw.TextStyle(
              //           fontSize: 12,
              //           fontWeight: pw.FontWeight.bold,
              //         ),
              //       ),
              //       pw.Text(
              //         '__${}_______',
              //         style: pw.TextStyle(
              //           fontSize: 11,
              //           fontWeight: pw.FontWeight.bold,
              //           decoration: pw.TextDecoration.underline,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              pw.Container(
                padding: pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
                child: pw.Column(children: [
                  pw.Row(children: [
                    pw.Row(children: [
                      pw.Padding(
                          padding: pw.EdgeInsets.only(right: 10),
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Faculty Name:',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                  ),
                                ),
                                pw.Text(
                                  'Rank:',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                  ),
                                ),
                                pw.Text(
                                  'Major Discipline',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                  ),
                                ),
                              ])),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              details['faculty_name'],
                              style: pw.TextStyle(
                                fontSize: 8,
                              ),
                            ),
                            pw.Text(
                              details['rank'],
                              style: pw.TextStyle(
                                fontSize: 8,
                              ),
                            ),
                            pw.Text(
                              details['major_discipline'],
                              style: pw.TextStyle(
                                fontSize: 8,
                              ),
                            ),
                          ])
                    ]),
                    pw.Spacer(),
                    pw.Spacer(),
                    pw.Row(
                      children: [
                        pw.Padding(
                            padding: pw.EdgeInsets.only(right: 10),
                            child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Designation:',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Text(
                                    'Status:',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Text(
                                    'Email Address:',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                    ),
                                  ),
                                ])),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                details['designation'],
                                style: pw.TextStyle(
                                  fontSize: 8,
                                ),
                              ),
                              pw.Text(
                                details['status'],
                                style: pw.TextStyle(
                                  fontSize: 8,
                                ),
                              ),
                              pw.Text(
                                details['email_address'],
                                style: pw.TextStyle(
                                  fontSize: 8,
                                ),
                              ),
                            ]),
                      ],
                    ),
                    pw.Spacer()
                  ]),
                  pw.SizedBox(height: 10)
                ]),
              ),

              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(.5),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(3),
                  4: pw.FlexColumnWidth(1.2),
                  5: pw.FlexColumnWidth(1.2),
                  6: pw.FlexColumnWidth(1),
                  7: pw.FlexColumnWidth(1),
                  8: pw.FlexColumnWidth(1),
                  9: pw.FlexColumnWidth(1.3),
                  10: pw.FlexColumnWidth(1.3),
                  11: pw.FlexColumnWidth(3),
                  12: pw.FlexColumnWidth(1.3),
                  13: pw.FlexColumnWidth(1.3)
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    decoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      paddedText(''),
                      paddedText(
                        'Subject ID',
                        align: pw.TextAlign.center,
                      ),
                      paddedText(
                        'Subject Code',
                        align: pw.TextAlign.center,
                      ),
                      paddedText(
                        'Subject Title',
                        align: pw.TextAlign.center,
                      ),
                      paddedText('Subject Credit',
                          align: pw.TextAlign.center, bold: true),
                      paddedText('Faculty Credit',
                          align: pw.TextAlign.center, bold: true),
                      paddedText('College',
                          align: pw.TextAlign.center, bold: true),
                      paddedText('Hrs./ Week',
                          align: pw.TextAlign.center, bold: true),
                      paddedText('Hrs./ Sem',
                          align: pw.TextAlign.center, bold: true),
                      paddedText('Section', align: pw.TextAlign.center),
                      paddedText('Days',
                          align: pw.TextAlign.center, bold: true),
                      paddedText('Time', align: pw.TextAlign.center),
                      paddedText('Room', align: pw.TextAlign.center),
                      paddedText('Total Studs', align: pw.TextAlign.center),
                    ],
                  ),
                  // Dynamic Rows
                  ...List.generate(regularSchedule.length, (index) {
                    final item = regularSchedule[index];
                    return tableRow(
                      index + 1,
                      item["schedule_id"] ?? "",
                      item["subject_code"] ?? "",
                      item["subject"] ?? "",
                      item["subject_credit"] ?? "",
                      item["faculty_credit"] ?? "",
                      item["college_code"] ?? "",
                      item["hr_per_week"] ?? "",
                      item["hr_per_sem"] ?? "",
                      item['section'] ?? "",
                      getMergedSchedule(List<Map<String,dynamic>>.from(item['schedule']))[0],
                      getMergedSchedule(List<Map<String,dynamic>>.from(item['schedule']))[1],
                      item["room"] ?? "",
                      item["total_students"] ?? "0", // Example: No. of students
                    );
                    //   {
                    //     "schedule_id": "124828",
                    //   "subject_code": "IT224",
                    //   "subject": "Systems Integration and Architecture",
                    //   "subject_credit": "3.0",
                    //   "faculty_credit": "4.25",
                    //   "college_code": "CITC",
                    //   "hr_per_week": "5.0",
                    //   "hr_per_sem": "90.0",
                    //   "section": "IT2R1",
                    //   "schedule": [
                    // {
                    //   "day": "F",
                    //   "time_start": "7:30",
                    //   "time_start_daytime": "AM",
                    //   "time_end": "10:00",
                    //   "time_end_daytime": "AM"
                    // }
                    //   ],
                    //   "room": "09-302(CITC Lab 3)",
                    //   "total_students": "37"
                    // }
                  }),
                ],
              ),
              pw.Table(
                  border: pw.TableBorder.symmetric(
                    outside: pw.BorderSide(color: PdfColors.black),
                  ),
                  columnWidths: {
                    0: pw.FlexColumnWidth(.5),
                    1: pw.FlexColumnWidth(1.5),
                    2: pw.FlexColumnWidth(1.5),
                    3: pw.FlexColumnWidth(3),
                    4: pw.FlexColumnWidth(1.2),
                    5: pw.FlexColumnWidth(1.2),
                    6: pw.FlexColumnWidth(1),
                    7: pw.FlexColumnWidth(1),
                    8: pw.FlexColumnWidth(1),
                    9: pw.FlexColumnWidth(1.3),
                    10: pw.FlexColumnWidth(1.3),
                    11: pw.FlexColumnWidth(3),
                    12: pw.FlexColumnWidth(1.3),
                    13: pw.FlexColumnWidth(1.3)
                  },
                  children: [
                    pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: [
                        paddedText(''),
                        paddedText(
                          '',
                        ),
                        paddedText(
                          ' ',
                        ),
                        paddedText('TOTAL', align: pw.TextAlign.end),
                        pw.Container(
                            child: paddedText(
                              totals['total_subject_credit'],
                              align: pw.TextAlign.center,
                            ),
                            decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black))),
                        pw.Container(
                            child: paddedText(
                              totals['total_faculty_credit'],
                              align: pw.TextAlign.center,
                            ),
                            decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black))),
                        paddedText(
                          '',
                        ),
                        pw.Container(
                            child: paddedText(
                              totals['total_weekly_hours'],
                              align: pw.TextAlign.center,
                            ),
                            decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black))),
                        paddedText(
                          '',
                        ),
                        paddedText(
                          '',
                        ),
                        paddedText(
                          '',
                        ),
                        paddedText(
                          '',
                        ),
                        paddedText(
                          '',
                        ),
                        pw.Container(
                            child: paddedText(
                              totals['all_total_students'],
                              align: pw.TextAlign.center,
                            ),
                            decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.black))),
                      ],
                    ),
                  ]),
              pw.SizedBox(height: 15),
              pw.Padding(
                  padding: pw.EdgeInsets.only(left: 100),
                  child: pw.Row(children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            "FACULTY CREDIT - - - - - - - - - - - - - - - - - - - - - - - - - - - -   ",
                            style: pw.TextStyle(fontSize: 7)),
                        pw.Text(
                            "DESIGNATION, LOAD RELEASED  - - - - - - - - - - 	                           ",
                            style: pw.TextStyle(fontSize: 7))
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(creditAndLoad["faculty_credit"],
                            style: pw.TextStyle(fontSize: 7)),
                        pw.Text(creditAndLoad["designation_load_released"],
                            style: pw.TextStyle(fontSize: 7))
                      ],
                    )
                  ])),
              pw.SizedBox(height: 20),
              pw.Text(
                'FACULTY LOAD STATISTICS',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                      border: pw.TableBorder.all(color: PdfColors.black)),
                  alignment: pw.Alignment.center,
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                            children: [
                              pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Number of Preparation',
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text('Average Class Size',
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text('Average Teaching Units',
                                        style: pw.TextStyle(fontSize: 8))
                                  ]),
                              pw.Padding(
                                  padding: pw.EdgeInsetsDirectional.symmetric(
                                      horizontal: 20),
                                  child: pw.Column(
                                      crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                      children: [
                                        pw.Text('=',
                                            style: pw.TextStyle(fontSize: 8)),
                                        pw.Text('=',
                                            style: pw.TextStyle(fontSize: 8)),
                                        pw.Text('=',
                                            style: pw.TextStyle(fontSize: 8))
                                      ])),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text(units["number_of_preparation"].toString(),
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text(units["average_class_size"].toString(),
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text(units['average_teaching_units'].toString(),
                                        style: pw.TextStyle(fontSize: 8))
                                  ]),
                            ]),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                            children: [
                              pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Number of Classes',
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text('Total Class Hour per week',
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text('Average Class Hour per day',
                                        style: pw.TextStyle(fontSize: 8))
                                  ]),
                              pw.Padding(
                                  padding: pw.EdgeInsetsDirectional.symmetric(
                                      horizontal: 20),
                                  child: pw.Column(
                                      crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                      children: [
                                        pw.Text('=',
                                            style: pw.TextStyle(fontSize: 8)),
                                        pw.Text('=',
                                            style: pw.TextStyle(fontSize: 8)),
                                        pw.Text('=',
                                            style: pw.TextStyle(fontSize: 8))
                                      ])),
                              pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text(units['number_of_classes'].toString(),
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text(units['total_class_hour_per_week'].toString(),
                                        style: pw.TextStyle(fontSize: 8)),
                                    pw.Text(units['average_class_hour_per_day'].toString(),
                                        style: pw.TextStyle(fontSize: 8))
                                    //"{"number_of_preparation":4.0,"average_class_size":26.0,"average_teaching_units":4.2,"number_of_classes":5.0,"total_class_hour_per_week":36.0,"average_class_hour_per_day":4.3}"
                                  ]),
                            ])
                      ])),


              pw.Text("TEACHER'S LOAD PROGRAM",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              generateScheduleTable(schedule),
              pw.SizedBox(height: 40),
                pw.Container(
                  alignment: pw.Alignment.centerLeft,
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
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('Equivalent teaching (hrs):',
                                          style: const pw.TextStyle(
                                              fontSize: 7.5)),
                                      pw.Text(
                                          '_____${emptyIfZero(eqTeaching)}____',
                                          style: const pw.TextStyle(
                                              decoration:
                                              pw.TextDecoration.underline,
                                              fontSize: 7.5))
                                    ]),
                                pw.Row(
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('Class Prep/Post (hrs):',
                                          style: const pw.TextStyle(
                                              fontSize: 7.5)),
                                      pw.Text(
                                          '____${emptyIfZero(prepHours)}_____',
                                          style: const pw.TextStyle(
                                              decoration:
                                              pw.TextDecoration.underline,
                                              fontSize: 7.5))
                                    ]),
                                pw.Row(
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('Consultation (hrs):',
                                          style: const pw.TextStyle(
                                              fontSize: 7.5)),
                                      pw.Text(
                                          '____${emptyIfZero(consultationHours)}_____',
                                          style: const pw.TextStyle(
                                              decoration:
                                              pw.TextDecoration.underline,
                                              fontSize: 7.5))
                                    ]),
                                pw.Row(
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('Quasi (hrs):',
                                          style: const pw.TextStyle(
                                              fontSize: 7.5)),
                                      pw.Text(
                                          '____${emptyIfZero(double.parse(quasi.toString()))}_____',
                                          style: const pw.TextStyle(
                                              decoration:
                                              pw.TextDecoration.underline,
                                              fontSize: 7.5))
                                    ]),
                                pw.Row(
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('Research and Extension (hrs):',
                                          style: const pw.TextStyle(
                                              fontSize: 7.5)),
                                      pw.Text('_________',
                                          style: const pw.TextStyle(
                                              decoration:
                                              pw.TextDecoration.underline,
                                              fontSize: 7.5))
                                    ]),
                                pw.Row(
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('Admin Designation (hrs):',
                                          style: const pw.TextStyle(
                                              fontSize: 7.5)),
                                      pw.Text('_________',
                                          style: const pw.TextStyle(
                                              decoration:
                                              pw.TextDecoration.underline,
                                              fontSize: 7.5))
                                    ]),
                                pw.Row(
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('TOTAL:',
                                          style: pw.TextStyle(
                                              fontSize: 7.5,
                                              fontWeight:
                                              pw.FontWeight.bold)),
                                      pw.Text(
                                          '____${emptyIfZero(totalHours)}_____',
                                          style: const pw.TextStyle(
                                              decoration:
                                              pw.TextDecoration.underline,
                                              fontSize: 7.5))
                                    ]),
                                pw.Row(
                                    mainAxisAlignment:
                                    pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text('Total Overload:',
                                          style: pw.TextStyle(
                                              fontSize: 7.5,
                                              fontWeight:
                                              pw.FontWeight.bold)),
                                      pw.Text(
                                          '____${emptyIfZero(totalOverload)}_____',
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
                pw.SizedBox(height: 30),
                pw.Container(
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Confirmed By:',
                                    textAlign: pw.TextAlign.start,
                                    style: pw.TextStyle(fontSize: 8)),
                                pw.SizedBox(height: 10),
                                pw.Column(
                                    crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Text(
                                        details['faculty_name']
                                            .toString()
                                            .toUpperCase(),
                                        style: pw.TextStyle(fontSize: 8),
                                      ),
                                      pw.Container(
                                          width: 150,
                                          height: 0.5,
                                          color: PdfColors.black),
                                      pw.Text('Faculty',
                                          style: pw.TextStyle(fontSize: 8)),
                                    ]),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Submitted By:',
                                    textAlign: pw.TextAlign.start,
                                    style: pw.TextStyle(fontSize: 8)),
                                pw.SizedBox(height: 10),
                                pw.Column(
                                    crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Text(
                                        "DR. JUNAR A. LANDICHO",
                                        style: pw.TextStyle(fontSize: 8),
                                      ),
                                      pw.Container(
                                          width: 150,
                                          height: 0.5,
                                          color: PdfColors.black),
                                      pw.Text('Faculty',
                                          style: pw.TextStyle(fontSize: 8)),
                                    ]),
                              ]),
                          pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Approved By:',
                                    textAlign: pw.TextAlign.start,
                                    style: pw.TextStyle(fontSize: 8)),
                                pw.SizedBox(height: 10),
                                pw.Column(
                                    crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Text(
                                        "DR. JOCELYN B. BARBOSA",
                                        style: pw.TextStyle(fontSize: 8),
                                      ),
                                      pw.Container(
                                          width: 150,
                                          height: 0.5,
                                          color: PdfColors.black),
                                      pw.Text('Faculty',
                                          style: pw.TextStyle(fontSize: 8)),
                                    ]),
                              ]),
                        ]))


              //
              // pw.SizedBox(height: 2),
              //
              // pw.Row(
              //   children: [
              //     pw.Expanded(
              //         flex: 2,
              //         child: pw.Column(
              //           crossAxisAlignment: pw.CrossAxisAlignment.end,
              //           children: [
              //             pw.Row(
              //                 mainAxisAlignment: pw.MainAxisAlignment.end,
              //                 children: [
              //                   pw.Text(
              //                     'Academic Equivalent Units:',
              //                     style: pw.TextStyle(fontSize: 6.5),
              //                   ),
              //                   pw.Text(
              //                     '___${units["academic_equivalent_units"]==0?'':units["academic_equivalent_units"]}______',
              //                     style: pw.TextStyle(
              //                         fontSize: 6.5,
              //                         decoration: pw.TextDecoration.underline),
              //                   ),
              //                 ]),
              //             pw.Row(
              //                 mainAxisAlignment: pw.MainAxisAlignment.end,
              //                 children: [
              //                   pw.Text(
              //                     'Administrative/Research Extension Units:',
              //                     style: pw.TextStyle(fontSize: 6.5),
              //                   ),
              //                   pw.Text(
              //                     '_____${units["administrative/research/extension_units"]==0?'':units["administrative/research/extension_units"]}_____',
              //                     style: pw.TextStyle(
              //                         fontSize: 6.5,
              //                         decoration: pw.TextDecoration.underline),
              //                   ),
              //                 ]),
              //             pw.Row(
              //                 mainAxisAlignment: pw.MainAxisAlignment.end,
              //                 children: [
              //                   pw.Text(
              //                     'Total Equivalent Units:',
              //                     style: pw.TextStyle(fontSize: 6.5),
              //                   ),
              //                   pw.Text(
              //                     '___${facultyCredit==0?'':units["faculty_credit"]}______',
              //                     style: pw.TextStyle(
              //                         fontSize: 6.5,
              //                         decoration: pw.TextDecoration.underline),
              //                   ),
              //                 ]),
              //           ],
              //         )),
              //     pw.Spacer(flex: 3),
              //     pw.Expanded(
              //         flex: 2,
              //         child: pw.Column(
              //           children: [
              //             pw.Row(children: [
              //               pw.Text(
              //                 'Total Contact Hours:',
              //                 style: pw.TextStyle(fontSize: 6.5),
              //               ),
              //               pw.Text(
              //                 '___${units["total_contact_hours"]==0?'':units["total_contact_hours"]}______',
              //                 style: pw.TextStyle(
              //                     fontSize: 6.5,
              //                     decoration: pw.TextDecoration.underline),
              //               ),
              //             ]),
              //             pw.Row(children: [
              //               pw.Text(
              //                 'nTotal No. Of Students:',
              //                 style: pw.TextStyle(fontSize: 6.5),
              //               ),
              //               pw.Text(
              //                 '___${units["total_no_of_students"]==0?'':units["total_no_of_students"]}______',
              //                 style: pw.TextStyle(
              //                     fontSize: 6.5,
              //                     decoration: pw.TextDecoration.underline),
              //               ),
              //             ]),
              //             pw.Row(children: [
              //               pw.Text(
              //                 'Number of Preparations:',
              //                 style: pw.TextStyle(fontSize: 6.5),
              //               ),
              //               pw.Text(
              //                 '___${units["number_of_preparation"]==0?'':units["number_of_preparation"]}______',
              //                 style: pw.TextStyle(
              //                     fontSize: 6.5,
              //                     decoration: pw.TextDecoration.underline),
              //               ),
              //             ]),
              //           ],
              //         )),
              //   ],
              // ),
              // pw.Container(
              //   height: 2, // Thickness of the line
              //   color: PdfColors.black,
              // ),
              // pw.SizedBox(height: 1),
              //
              // pw.Center(
              //   child: pw.Text(
              //     "TEACHER'S LOAD PROGRAM",
              //     style: pw.TextStyle(
              //       fontSize: 10,
              //       fontWeight: pw.FontWeight.bold,
              //     ),
              //   ),
              // ),
              // pw.SizedBox(height: 1), // Reduced spacing
              // generateScheduleTable(schedule),
            ],


          )]

      ),
    );
    // pdf.addPage(
    //   pw.Page(
    //       pageFormat: PdfPageFormat.legal,
    //       margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    //       build: (pw.Context context) {
    //         return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,children:
    //         [
    //           pw.Container(
    //             child: pw.Column(
    //               crossAxisAlignment: pw.CrossAxisAlignment.start,
    //               children: [
    //
    //                 pw.Text(
    //                   'SUMMARY',
    //                   style: pw.TextStyle(
    //                     fontSize: 11,
    //                     fontWeight: pw.FontWeight.bold,
    //                     decoration: pw.TextDecoration.underline,
    //                   ),
    //                 ),
    //                 pw.SizedBox(height: 5),
    //                 pw.Container(
    //                   width: 178,
    //                   padding: pw.EdgeInsets.only(left: 20),
    //                   child: pw.Expanded(
    //                     flex: 1,
    //                     child: pw.Column(
    //                         crossAxisAlignment: pw.CrossAxisAlignment.end,
    //                         children: [
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('Equivalent teaching (hrs):',
    //                                     style:
    //                                     const pw.TextStyle(fontSize: 7.5)),
    //                                 pw.Text('_____${emptyIfZero(eqTeaching)}____',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('Class Prep/Post (hrs):',
    //                                     style:
    //                                     const pw.TextStyle(fontSize: 7.5)),
    //                                 pw.Text('____${emptyIfZero(prepHours)}_____',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('Consultation (hrs):',
    //                                     style:
    //                                     const pw.TextStyle(fontSize: 7.5)),
    //                                 pw.Text('____${emptyIfZero(consultationHours)}_____',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('Quasi (hrs):',
    //                                     style:
    //                                     const pw.TextStyle(fontSize: 7.5)),
    //                                 pw.Text('_________',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('Research and Extension (hrs):',
    //                                     style:
    //                                     const pw.TextStyle(fontSize: 7.5)),
    //                                 pw.Text('_________',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('Admin Designation (hrs):',
    //                                     style:
    //                                     const pw.TextStyle(fontSize: 7.5)),
    //                                 pw.Text('_________',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('TOTAL:',
    //                                     style: pw.TextStyle(
    //                                         fontSize: 7.5,
    //                                         fontWeight: pw.FontWeight.bold)),
    //                                 pw.Text('____${emptyIfZero(totalHours)}_____',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                           pw.Row(
    //                               mainAxisAlignment: pw.MainAxisAlignment.end,
    //                               children: [
    //                                 pw.Text('Total Overload:',
    //                                     style: pw.TextStyle(
    //                                         fontSize: 7.5,
    //                                         fontWeight: pw.FontWeight.bold)),
    //                                 pw.Text('____${emptyIfZero(totalOverload)}_____',
    //                                     style: const pw.TextStyle(
    //                                         decoration:
    //                                         pw.TextDecoration.underline,
    //                                         fontSize: 7.5))
    //                               ]),
    //                         ]),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),
    //           pw.SizedBox(height: 10),
    //
    //           pw.Container(
    //             child: pw.Column(
    //               children: [
    //
    //                 pw.Text(
    //                   'I hereby certify that the above information is true and correct',
    //                   style: pw.TextStyle(
    //                     fontSize: 8,
    //                     fontWeight: pw.FontWeight.normal,
    //                   ),
    //                   textAlign: pw.TextAlign.center,
    //                 ),
    //                 pw.SizedBox(height: 5),
    //                 pw.Row(
    //                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    //                   children: [
    //                     pw.Expanded(
    //                       child: pw.Column(
    //                         crossAxisAlignment: pw.CrossAxisAlignment.center,
    //                         children: [
    //                           pw.Text(
    //                             '____________${details['faculty_name'].toString().toUpperCase()}_________',
    //                             textAlign: pw.TextAlign.center,
    //                             style: pw.TextStyle(fontSize: 7.5,fontWeight: pw.FontWeight.bold),
    //                           ),
    //                           pw.Text(
    //                             'Name and Signature of Faculty',
    //                             style: pw.TextStyle(fontSize: 7.5),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                     pw.Expanded(
    //                       child: pw.Column(
    //                         crossAxisAlignment: pw.CrossAxisAlignment.center,
    //                         children: [
    //                           pw.Text(
    //                             '_______________',
    //                             style:  pw.TextStyle(
    //                                 fontSize: 7.5,
    //                                 fontWeight: pw.FontWeight.bold,
    //                                 decoration: pw.TextDecoration.underline),
    //                           ),
    //                           pw.Text(
    //                             'Date',
    //                             style: pw.TextStyle(fontSize: 7.5),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ],
    //             ),
    //           ),
    //           pw.SizedBox(height: 5),
    //           // Section with "Recommending Approval" and "Approved"
    //           pw.Container(
    //             child: pw.Row(
    //               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    //               children: [
    //                 pw.Expanded(
    //                   child: pw.Column(
    //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
    //                     children: [
    //                       pw.Text(
    //                         'Recommending Approval:',
    //                         style: pw.TextStyle(
    //                             fontSize: 7.5, fontWeight: pw.FontWeight.bold),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.SizedBox(height: 5),
    //                       pw.Text(
    //                         '_____________________',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.Text(
    //                         'Name and Signature of Department Head',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //                 pw.Expanded(
    //                   child: pw.Column(
    //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
    //                     children: [
    //                       pw.Text(
    //                         '',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.SizedBox(height: 5),
    //                       pw.Text(
    //                         '_____________________',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.Text(
    //                         'Date',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //                 pw.Expanded(
    //                   child: pw.Column(
    //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
    //                     children: [
    //                       pw.Text(
    //                         'Approved:',
    //                         style: pw.TextStyle(
    //                             fontSize: 7.5, fontWeight: pw.FontWeight.bold),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.SizedBox(height: 5),
    //                       pw.Text(
    //                         '_____________________',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.Text(
    //                         'Name and Signature of Dean',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //                 pw.Expanded(
    //                   child: pw.Column(
    //                     crossAxisAlignment: pw.CrossAxisAlignment.center,
    //                     children: [
    //                       pw.Text(
    //                         '',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.SizedBox(height: 5),
    //                       pw.Text(
    //                         '__________${date}___________',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                       pw.Text(
    //                         'Date',
    //                         style: pw.TextStyle(fontSize: 7.5),
    //                         textAlign: pw.TextAlign.center,
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ]);
    //       }
    //   )
    // );
    // pdf.addPage(pw.Page(
    //     pageFormat: PdfPageFormat.legal,
    //     margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    //     build: (context) => pw.Column(
    //         crossAxisAlignment: pw.CrossAxisAlignment.center,
    //         children: [
    //         ])));


    return pdf; // Return the generated PDF
  }
  static String emptyIfZero(double number)=> number<=0?"":"$number";
  static double getTotalHours (List<Map<String, dynamic>> schedule){
    final List<String> days = ["M", "T", "W", "Th", "F", "S"];
    Map<String, double> totalHoursPerDay = {for (var day in days) day: 0};

    for (var entry in schedule) {
      final schedules = entry["schedule"] as List;
      for (var sched in schedules) {
        final day = sched["day"];
        final startTime =
        parseTime(sched["time_start"], sched["time_start_daytime"]);
        final endTime = parseTime(sched["time_end"], sched["time_end_daytime"]);
        totalHoursPerDay[day] = totalHoursPerDay[day]! +
            endTime.difference(startTime).inMinutes /
                30 *
                30 /
                60; // Half-hour increments
      }
    }
    double totalHours = 0;
    for (var day in days) {
      totalHours += totalHoursPerDay[day] ?? 0;
    }
    return totalHours;
  }


// Function to generate the weekly schedule table
  static pw.Table generateScheduleTable(List<Map<String, dynamic>> schedule) {
    final List<String> timeSlots = [
      "7:00 AM - 7:30 AM",
      "7:30 AM - 8:00 AM",
      "8:00 AM - 8:30 AM",
      "8:30 AM - 9:00 AM",
      "9:00 AM - 9:30 AM",
      "9:30 AM - 10:00 AM",
      "10:00 AM - 10:30 AM",
      "10:30 AM - 11:00 AM",
      "11:00 AM - 11:30 AM",
      "11:30 AM - 12:00 PM",
      "12:00 PM - 12:30 PM",
      "12:30 PM - 1:00 PM",
      "1:00 PM - 1:30 PM",
      "1:30 PM - 2:00 PM",
      "2:00 PM - 2:30 PM",
      "2:30 PM - 3:00 PM",
      "3:00 PM - 3:30 PM",
      "3:30 PM - 4:00 PM",
      "4:00 PM - 4:30 PM",
      "4:30 PM - 5:00 PM",
      "5:00 PM - 5:30 PM",
      "5:30 PM - 6:00 PM",
      "6:00 PM - 6:30 PM",
      "6:30 PM - 7:00 PM",
      "7:00 PM - 7:30 PM",
      "7:30 PM - 8:00 PM",
      "8:00 PM - 8:30 PM",
      "8:30 PM - 9:00 PM"
    ];

    final List<String> days = ["M", "T", "W", "Th", "F", "S"];
    final Map<String, String> dayMap = {
      "M": "MON",
      "T": "TUE",
      "W": "WED",
      "Th": "THURS",
      "F": "FRI",
      "S": "SAT"
    };

    final fullDays = days.map((day) => dayMap[day]!).toList();
    final random = Random();
    final subjectColors = <String, PdfColor>{};
    final Set<String> blacklist = <String>{};

    for (var entry in schedule) {
      subjectColors.putIfAbsent(entry["schedule_id"]??entry['subject_code'], () {
        final hue = random.nextDouble();
        return pdfColorFromHsl(hue, 0.6, 0.8);
      });
    }
    // Calculate total hours per day
    final Map<String, double> totalHoursPerDay = {for (var day in days) day: 0};
    for (var entry in schedule) {
      final schedules = entry["schedule"] as List;
      for (var sched in schedules) {
        final day = sched["day"];
        final startTime =
        parseTime(sched["time_start"], sched["time_start_daytime"]);
        final endTime = parseTime(sched["time_end"], sched["time_end_daytime"]);
        totalHoursPerDay[day] = totalHoursPerDay[day]! +
            endTime.difference(startTime).inMinutes /
                30 *
                30 /
                60; // Half-hour increments
      }
    }

    return pw.Table(
      border: pw.TableBorder(
          verticalInside: pw.BorderSide(color: PdfColors.black),
          left: pw.BorderSide(color: PdfColors.black),
          right: pw.BorderSide(color: PdfColors.black),
          bottom: pw.BorderSide(color: PdfColors.black),
          top: pw.BorderSide(color: PdfColors.black)),
      columnWidths: {
        0: pw.FlexColumnWidth(1.5),
        for (int i = 1; i <= days.length; i++) i: pw.FlexColumnWidth(0.8),
      },
      children: [
        // Header Row
        pw.TableRow(
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                  border: pw.TableBorder.all(color: PdfColors.black)),
              alignment: pw.Alignment.center,
              child: pw.Text("TIME",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ),
            ...fullDays.map((day) => pw.Container(
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                  border: pw.TableBorder.all(color: PdfColors.black)),
              child: pw.Text(day,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 8)),
            )),
          ],
        ),
        // Time Slot Rows
        ...timeSlots.map((timeSlot) {
          // Find the maximum content size for this row
          String maxInfo = "";
          final cellContents = days.map((day) {
            final matchingSubjects = schedule.where((entry) {
              return (entry["schedule"] as List).any((s) {
                if (s["day"] == day) {
                  final startTime =
                  parseTime(s["time_start"], s["time_start_daytime"]);
                  final endTime =
                  parseTime(s["time_end"], s["time_end_daytime"]);
                  final slotStart = parseTime(
                    timeSlot.split(" - ")[0],
                    timeSlot.contains("AM") ? "AM" : "PM",
                  );
                  return (slotStart.isAtSameMomentAs(startTime) ||
                      slotStart.isAfter(startTime)) &&
                      slotStart.isBefore(endTime);
                }
                return false;
              });
            }).toList();
            //[...info.map((data)=>List.generate(data.length, (_) => "_").join(""))].join('\n')

            if (matchingSubjects.isNotEmpty) {
              final firstSubject = matchingSubjects.first;
              final subjectKey = "${firstSubject["schedule_id"]??firstSubject["subject_code"]}-${day}";
              final subjectColor =
                  subjectColors[firstSubject["schedule_id"]??firstSubject["subject_code"]] ??
                      PdfColors.white;
              final section = firstSubject["section"] ?? '';
              final room = firstSubject["room"] ?? '';
              final info = [
                firstSubject["subject_code"] ?? 'Unknown',
                firstSubject["subject"] ?? 'No Subject',
                section.length == 0 ? "__" : section,
                room.length == 0 ? "_" : room,
              ];
              if (!blacklist.contains(subjectKey)) {
                blacklist.add(subjectKey);

                return {
                  "content": info.join('\n'),
                  "color": subjectColor,
                };
              } else {
                return {"content": "_", "color": subjectColor};
              }
            }
            return {"content": "", "color": PdfColors.white};
          }).toList();
          final toSort = [...cellContents];
          toSort.sort((a, b) {
            final bContent = b['content'] as String;
            final aContent = a['content'] as String;
            return bContent.length - aContent.length;
          });

          maxInfo = toSort[0]['content'] as String;

          // Adjust other cells to match the maximum content size
          return pw.TableRow(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.TableBorder(
                        top: pw.BorderSide(color: PdfColors.black))),
                padding: pw.EdgeInsets.only(left: 10),
                child: pw.Text(timeSlot.replaceAll(RegExp(r' AM| PM'), ''),
                    style: pw.TextStyle(fontSize: 8)),
                alignment: pw.Alignment.centerLeft,
              ),
              ...cellContents.map((cellContent) {
                late var content = cellContent["content"] as String;
                final color = cellContent["color"] as PdfColor;

                if (content.isNotEmpty) {
                  if (content != "_") {
                    final richContent = content.split("\n");
                    return pw.Container(
                      constraints: pw.BoxConstraints(maxHeight:24,minHeight: 0),
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.all(0.5),
                      color: color,
                      child: pw.RichText(
                        text: pw.TextSpan(
                            children: [
                              ...richContent.map((data) => pw.TextSpan(
                                  text: richContent[richContent.length - 1] !=
                                      data ||
                                      richContent[1] != data
                                      ? data + "\n"
                                      : data,
                                  style: pw.TextStyle(
                                      color: data == "_" || data == "__"
                                          ? color
                                          : PdfColors.black,
                                      fontSize: 5),
                                  children: [
                                    if (data == richContent[1])
                                      content.length < maxInfo.length
                                          ? pw.TextSpan(
                                          text: List.generate(
                                              maxInfo
                                                  .split("\n")[1]
                                                  .length -
                                                  richContent[1].length,
                                                  (_) => "_").join("")+"\n" ,
                                          style: pw.TextStyle(
                                              fontSize: 5, color: color))
                                          : pw.TextSpan(text:""),
                                  ])),
                              if( content.length < maxInfo.length)
                                pw.TextSpan(text:"\n_"  ,style: pw.TextStyle(
                                    fontSize: 5, color: color))
                            ]),
                        textAlign: pw.TextAlign.center,
                      ),
                    );
                  } else {
                    return pw.Container(
                      constraints: pw.BoxConstraints(maxHeight:24,minHeight: 0),
                      padding: pw.EdgeInsets.all(0.5),
                      color: color,
                      child: pw.Text(
                        [
                          ..."${maxInfo}".split("\n").map((data) =>
                              List.generate(data.length, (_) => "_").join(""))
                        ].join('\n'),
                        style: pw.TextStyle(
                            color: color, fontSize: maxInfo == '_' ? 8 : 5),
                        textAlign: pw.TextAlign.center,
                      ),
                    );
                  }
                } else {
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                        border: pw.TableBorder(
                            top: pw.BorderSide(color: PdfColors.black))),
                    child: pw.Text("_",
                        style: pw.TextStyle(color: color, fontSize: 8)),
                  );
                }
              }),
            ],
          );
        }),

        pw.TableRow(
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                  border: pw.TableBorder(
                      top: pw.BorderSide(color: PdfColors.black))),
              alignment: pw.Alignment.centerLeft,
              padding: pw.EdgeInsets.only(left: 10),
              child: pw.Text("TOTAL HOURS",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ),
            ...days.map((day) => pw.Container(
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                  border: pw.TableBorder(
                      top: pw.BorderSide(color: PdfColors.black))),
              child: pw.Text("${totalHoursPerDay[day]}",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 8)),
            )),
          ],
        ),
      ],
    );

  }




// Function to calculate total subject hours


  static PdfColor pdfColorFromHsl(double hue, double saturation, double lightness, [double alpha = 1.0]) {
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



  static DateTime parseTime(String time, String period) {
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

  static String getOrdinalFromString(String input) {
    RegExp regExp = RegExp(r'(\d+)(st|nd|rd|th)');
    Match? match = regExp.firstMatch(input);

    if (match != null) {
      int number = int.parse(match.group(1)!);
      String suffix = match.group(2)!;

      Map<String, String> ordinalWords = {
        '1st': 'first',
        '2nd': 'second',
        "3rd": "third"
      };

      String key = '$number$suffix';
      return ordinalWords[key] ?? '${number}th'; // Fallback for numbers not in the map
    } else {
      throw FormatException('No ordinal number found in the input string');
    }
  }


  static pw.Widget paddedText(String text,
      {double fontSize = 7,
        pw.TextAlign align = pw.TextAlign.left,
        double insets = 3,
        bold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(insets),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
            fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null),
      ),
    );
  }

  static pw.TableRow tableRow(
      int no,
      String id,
      String code,
      String title,
      String subCredit,
      String facultyCredit,
      String collegeCode,
      String hoursWeek,
      String hoursSem,
      String section,
      String days,
      String time,
      String room,
      String students) {
    return pw.TableRow(
      children: [
        paddedText('$no',align: pw.TextAlign.center),
        paddedText( id),
        paddedText( code),
        paddedText( title),
        paddedText( subCredit,align: pw.TextAlign.center),
        paddedText( facultyCredit,align: pw.TextAlign.center),
        paddedText( collegeCode,align: pw.TextAlign.center),
        paddedText( hoursWeek,align: pw.TextAlign.center),
        paddedText( hoursSem,align: pw.TextAlign.center),
        paddedText( section,align: pw.TextAlign.center),
        paddedText( days,align: pw.TextAlign.center),
        paddedText( time,align: pw.TextAlign.center),
        paddedText( room,align: pw.TextAlign.center),
        paddedText( students,align: pw.TextAlign.center),
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
}
