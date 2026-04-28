import 'package:flutter_test/flutter_test.dart';
import 'package:smart_timetable_builder/models/models.dart';

void main() {
  test('TimetableProject.fromMap converts JSON lists to typed model lists', () {
    final project = TimetableProject.fromMap({
      'id': 'timetable-1',
      'class_name': 'BCA A',
      'working_days': 5,
      'slots_per_day': 6,
      'subjects': [
        {
          'id': 'subject-1',
          'name': 'Math',
          'facultyName': 'Dr Rao',
          'hoursPerWeek': 4,
        }
      ],
      'rooms': [
        {
          'id': 'room-1',
          'room_id': '101',
          'capacity': 60,
        }
      ],
      'faculty_availability': [
        {
          'facultyName': 'Dr Rao',
          'availableDays': [0, 1, 2],
          'availableSlots': [0, 1, 2, 3],
        }
      ],
      'entries': [
        {
          'subjectName': 'Math',
          'facultyName': 'Dr Rao',
          'roomId': '101',
          'day': 0,
          'slot': 0,
        }
      ],
      'time_slots': [
        {
          'startTime': '09:00',
          'endTime': '10:00',
        }
      ],
      'created_at': '2026-04-28T07:30:00Z',
    });

    expect(project.facultyAvailability, isA<List<FacultyAvailability>>());
    expect(project.facultyAvailability.single.facultyName, 'Dr Rao');
    expect(project.entries, isA<List<TimetableEntry>>());
    expect(project.timeSlots, isA<List<TimeSlotDef>>());
  });
}
