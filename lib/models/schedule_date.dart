class Schedule {
  final String subjectCode;
  final String subject;
  final String section;
  final String schedule;

  Schedule({
    required this.subjectCode,
    required this.subject,
    required this.section,
    required this.schedule,
  });

  @override
  String toString() {
    return 'Subject Code: $subjectCode, Subject: $subject, Section: $section, Schedule: $schedule';
  }
}
