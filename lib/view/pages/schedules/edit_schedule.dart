import 'package:faculty_load/view/pages/schedules/view_current_schedule.dart';
import 'package:flutter/material.dart';

class EditSubjectScreen extends StatefulWidget {
  final Map<String, dynamic> subject;
  final List<Map<String, dynamic>> allSubjects;
  final List<String> editableSubjectCodes;

  EditSubjectScreen({
    required this.subject,
    required this.allSubjects,
    required this.editableSubjectCodes,
  });

  @override
  _EditSubjectScreenState createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  late TextEditingController roomController;
  late List<Map<String, dynamic>> schedule;
  final Map<String, String> dayMapping = {
    "M": "Monday",
    "T": "Tuesday",
    "W": "Wednesday",
    "Th": "Thursday",
    "F": "Friday",
    "S": "Saturday",
  };
  late Map<String, dynamic> oldSubject =widget.subject;
  bool canPop=false;

  @override
  void initState() {
    super.initState();
    roomController = TextEditingController(text: widget.subject['room'] ?? '');
    schedule = List<Map<String, dynamic>>.from(widget.subject['schedule']);
  }

  Future<void> _editDay(Map<String, dynamic> sched) async {
    String selectedDay = sched['day']; // Keep current day as default.
    final newDay = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Day'),
          content: DropdownButton<String>(
            value: selectedDay,
            isExpanded: true,
            items: dayMapping.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              selectedDay = value ?? selectedDay; // Update selected day

              Navigator.pop(context, selectedDay);
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () =>
                  Navigator.pop(context, null), // Close without changes.
            ),
          ],
        );
      },
    );

    if (newDay != null && newDay != sched['day']) {
      setState(() {
        sched['day'] = newDay; // Update the day in schedule.
      });
    }
  }

  Future<bool> _editTime(Map<String, dynamic> sched, String key,oldSched) async {
    final initialTime = TimeOfDay(
      hour: formatTo24Hours(int.parse(sched[key].split(':')[0]),sched['${key}_daytime']),
      minute: int.parse(sched[key].split(':')[1]),
    );

    final pickedTime =
    await showTimePicker(context: context, initialTime: initialTime);

    if (pickedTime != null) {
      // Define the allowable time range
      final startTime = const TimeOfDay(hour: 7, minute: 0); // 7:00 AM
      final endTime = const TimeOfDay(hour: 21, minute: 30); // 9:30 PM

      // Check if the picked time is within the allowable range
      bool isWithinRange = (pickedTime.hour > startTime.hour ||
          (pickedTime.hour == startTime.hour &&
              pickedTime.minute >= startTime.minute)) &&
          (pickedTime.hour < endTime.hour ||
              (pickedTime.hour == endTime.hour &&
                  pickedTime.minute <= endTime.minute));

      if (!isWithinRange) {
        // Show an AlertDialog if the time is out of range
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Invalid Time'),
              content: const Text(
                  'The selected time must be between 7:00 AM and 9:30 PM.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {

                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return false;
      }

      // Additional validation for `time_end`
      if (key == "time_end") {
        var startHour = int.parse(sched['time_start'].split(':')[0]);
        final startMinute = int.parse(sched['time_start'].split(':')[1]);


        startHour =formatTo24Hours(startHour,sched['time_start_daytime']);

        final startTime = TimeOfDay(hour: startHour, minute: startMinute);

        // Check if `pickedTime` is after `startTime`
        bool isAfterStartTime = (pickedTime.hour > startTime.hour) ||
            (pickedTime.hour == startTime.hour &&
                pickedTime.minute > startTime.minute);

        if (!isAfterStartTime) {
          // Show an AlertDialog if `time_end` is not after `time_start`
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Invalid Time'),
                content: const Text(
                    '`time end` must be later than `time start`. Please choose a valid time.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {

                      setState(() {
                        sched=oldSched;
                      });
                      print(sched);
                      print(oldSched);
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          return false;
        }
      }

      // If all validations pass, update the schedule
      setState(() {
        sched[key] =
        '${pickedTime.hour - 12 <= 0 ? pickedTime.hour : pickedTime.hour - 12}:${pickedTime.minute.toString().padLeft(2, '0')}';
        sched['${key}_daytime'] =
        pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
      });
      return true;
    }
    return true;
  }


  Map<String, dynamic>? _isScheduleConflict(
      Map<String, dynamic> newSchedule, i) {

    for (var subject in widget.allSubjects) {
      if (subject['subject_code'] == widget.subject['subject_code']) continue;

      for (var existingSchedule in subject['schedule']) {
        if (existingSchedule['day'] == newSchedule['day']) {
          // Convert existing schedule times to 24-hour format
          final existingStart = _convertTo24Hour(
            existingSchedule['time_start'],
            existingSchedule['time_start_daytime'],
          );
          final existingEnd = _convertTo24Hour(
            existingSchedule['time_end'],
            existingSchedule['time_end_daytime'],
          );

          // Convert new schedule times to 24-hour format
          final newStart = _convertTo24Hour(
            newSchedule['time_start'],
            newSchedule['time_start_daytime'],
          );
          final newEnd = _convertTo24Hour(
            newSchedule['time_end'],
            newSchedule['time_end_daytime'],
          );

          // Check for overlap
          if (!(newEnd <= existingStart || newStart >= existingEnd)) {
            // Return the conflicting subject and schedule details
            return {
              'subject': subject['subject'],
              'conflicting_schedule': existingSchedule,
            };
          }
        }
      }
    }
    var currentSchedule = [...schedule];
    currentSchedule.removeAt(i);
    for (var schedule in currentSchedule){
      if (schedule['day'] == newSchedule['day']) {
        // Convert existing schedule times to 24-hour format
        final existingStart = _convertTo24Hour(
          schedule['time_start'],
          schedule['time_start_daytime'],
        );
        final existingEnd = _convertTo24Hour(
          schedule['time_end'],
          schedule['time_end_daytime'],
        );

        // Convert new schedule times to 24-hour format
        final newStart = _convertTo24Hour(
          newSchedule['time_start'],
          newSchedule['time_start_daytime'],
        );
        final newEnd = _convertTo24Hour(
          newSchedule['time_end'],
          newSchedule['time_end_daytime'],
        );

        // Check for overlap
        if (!(newEnd <= existingStart || newStart >= existingEnd)) {
          // Return the conflicting subject and schedule details
          return {
            'subject':" ${widget.subject['subject']} (currently editing)",
            'conflicting_schedule': schedule,
          };
        }
      }
    }
    return null; // No conflict
  }

  int _convertTo24Hour(String time, String daytime) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (daytime == 'PM' && hour != 12) {
      hour += 12; // Convert PM to 24-hour format
    } else if (daytime == 'AM' && hour == 12) {
      hour = 0; // Convert 12 AM to 00:00
    }

    return hour * 60 +
        minute; // Return time as total minutes for easier comparison
  }
  int formatTo24Hours(int hour, String period) {
    // Convert 12-hour format to 24-hour format
    if (period == 'PM' && hour != 12) return hour + 12;
    if (period == 'AM' && hour == 12) return 0;
    return hour;
  }

  void _save() {
    List<Map<String, dynamic>> conflict = [];

    for (int i = 0; i < schedule.length; i++) {
      final conflictedSchedule = _isScheduleConflict(schedule[i], i);
      if (conflictedSchedule != null) {
        conflict.add(conflictedSchedule);
      }
    }
    if (conflict.isNotEmpty) {
      // Show conflict details in a dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Conflict Detected'),
            content: Container(
              height: 300.0, // Change as per your requirement
              width: 300.0, // Change as per your requirement
              child: ListView.builder(
                itemCount: conflict.length,
                itemBuilder: (context, index) {
                  final conflictingSubject = conflict[index]['subject'];
                  final conflictingSchedule = conflict[index];
                  return Text(
                    'The schedule conflicts with:\n\n'
                        'Subject: $conflictingSubject\n'
                        'Day: ${conflictingSchedule['conflicting_schedule']['day']}\n'
                        'Time: ${conflictingSchedule['conflicting_schedule']['time_start']} ${conflictingSchedule['conflicting_schedule']['time_start_daytime']} - '
                        '${conflictingSchedule['conflicting_schedule']['time_end']} ${conflictingSchedule['conflicting_schedule']['time_end_daytime']}',

                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      return;
    }

    // Save changes if no conflict
    Navigator.pop(context, {
      ...widget.subject,
      'room': roomController.text,
      'schedule': schedule,
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult : (didPop,result) async {
        // Call the _save method to check for conflicts
        List<Map<String, dynamic>> conflict = [];

        for (int i = 0; i < schedule.length; i++) {
          final conflictedSchedule = _isScheduleConflict(schedule[i], i);
          if (conflictedSchedule != null) {
            conflict.add(conflictedSchedule);
          }
        }

        if (conflict.isNotEmpty) {
          // Show conflict details in a dialog
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Conflict Detected'),
                content: Container(
                  height: 300.0, // Adjust as needed
                  width: 300.0, // Adjust as needed
                  child: ListView.builder(
                    itemCount: conflict.length,
                    itemBuilder: (context, index) {
                      final conflictingSubject = conflict[index]['subject'];
                      final conflictingSchedule = conflict[index];
                      return Text(
                        'The schedule conflicts with:\n\n'
                            'Subject: $conflictingSubject\n'
                            'Day: ${conflictingSchedule['conflicting_schedule']['day']}\n'
                            'Time: ${conflictingSchedule['conflicting_schedule']['time_start']} ${conflictingSchedule['conflicting_schedule']['time_start_daytime']} - '
                            '${conflictingSchedule['conflicting_schedule']['time_end']} ${conflictingSchedule['conflicting_schedule']['time_end_daytime']}',
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );

          return; // Prevent navigation due to conflicts
        }

        // If no conflicts, save changes and allow navigation
        _save();
        return; // Allow navigation
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Edit Subject')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: roomController,
                decoration: InputDecoration(labelText: 'Room'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: schedule.length,
                  itemBuilder: (context, index) {
                    final sched = schedule[index];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Text('Day: ${dayMapping[sched['day']]}'),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () =>
                                  _editDay(sched), // Trigger day editing.
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Start: ${sched['time_start']} ${sched['time_start_daytime']}'),
                            Text(
                                'End: ${sched['time_end']} ${sched['time_end_daytime']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.access_time),
                          onPressed: () async {
                            final oldSchedData = oldSubject['schedule'][index];
                            final oldSched = {...Map<String, dynamic>.from(oldSchedData)};
                            bool hasNoErrors = true;

                            // Edit time_start and time_end
                            await _editTime(sched, 'time_start', oldSchedData);
                            hasNoErrors = await _editTime(sched, 'time_end', oldSchedData);
                            if (!hasNoErrors) {
                              setState(() {
                                sched['time_start'] = oldSched['time_start'];
                                sched['time_end'] = oldSched['time_end'];
                              });
                            }

                            double calculateTotalHours(Map<String, dynamic> schedule) {
                              final startTime = TimeOfDay(
                                hour: formatTo24Hours(int.parse(schedule["time_start"].split(':')[0]), schedule['time_start_daytime']),
                                minute: int.parse(schedule['time_start'].split(':')[1]),
                              );
                              final endTime = TimeOfDay(
                                hour: formatTo24Hours(int.parse(schedule["time_end"].split(':')[0]), schedule['time_end_daytime']),
                                minute: int.parse(schedule['time_end'].split(':')[1]),
                              );

                              final startMinutes = startTime.hour * 60 + startTime.minute;
                              final endMinutes = endTime.hour * 60 + endTime.minute;

                              return (endMinutes - startMinutes) / 60.0;
                            }

                            final oldTotalHours = calculateTotalHours(oldSched);
                            final newTotalHours = calculateTotalHours(sched);

                            if (oldTotalHours != newTotalHours && newTotalHours > 0 && oldTotalHours > 0) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Invalid Schedule'),
                                    content: Text(
                                        'The total hours of the new schedule must match the old schedule. Expecting $oldTotalHours hours but found $newTotalHours hours.'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            sched['time_start'] = oldSched['time_start'];
                                            sched['time_end'] = oldSched['time_end'];
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(onPressed: _save, child: Text('Save')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ViewSchedule(
                            allSubjects: widget.allSubjects,
                          ))),
                      child: Text('Preview Schedule')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}