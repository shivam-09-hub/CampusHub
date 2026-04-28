import '../models/models.dart';

class DemoData {
  static TimetableProject create() {
    final subjects = [
      SubjectModel(id: 's1', name: 'Mathematics', facultyName: 'Dr. Sharma', hoursPerWeek: 5, colorIndex: 0),
      SubjectModel(id: 's2', name: 'Physics', facultyName: 'Prof. Mehta', hoursPerWeek: 4, colorIndex: 1),
      SubjectModel(id: 's3', name: 'Chemistry', facultyName: 'Dr. Patel', hoursPerWeek: 4, colorIndex: 2),
      SubjectModel(id: 's4', name: 'English', facultyName: 'Ms. Joshi', hoursPerWeek: 3, colorIndex: 3),
      SubjectModel(id: 's5', name: 'Computer Science', facultyName: 'Mr. Singh', hoursPerWeek: 4, colorIndex: 4),
    ];

    final rooms = [
      RoomModel(id: 'r1', roomId: 'Room 101', capacity: 40),
      RoomModel(id: 'r2', roomId: 'Room 102', capacity: 35),
      RoomModel(id: 'r3', roomId: 'Lab A', capacity: 30),
    ];

    final availability = [
      FacultyAvailability(
        facultyName: 'Dr. Sharma',
        availableDays: [0, 1, 2, 3, 4],
        availableSlots: [0, 1, 2, 3, 4, 5],
      ),
      FacultyAvailability(
        facultyName: 'Prof. Mehta',
        availableDays: [0, 1, 2, 3, 4],
        availableSlots: [0, 1, 2, 3, 4, 5],
      ),
      FacultyAvailability(
        facultyName: 'Dr. Patel',
        availableDays: [0, 1, 2, 3, 4],
        availableSlots: [0, 1, 2, 3, 4, 5],
      ),
      FacultyAvailability(
        facultyName: 'Ms. Joshi',
        availableDays: [0, 1, 2, 3],
        availableSlots: [1, 2, 3, 4],
      ),
      FacultyAvailability(
        facultyName: 'Mr. Singh',
        availableDays: [0, 1, 2, 3, 4],
        availableSlots: [2, 3, 4, 5],
      ),
    ];

    return TimetableProject(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      className: 'Class 11 - Science',
      workingDays: 5,
      slotsPerDay: 6,
      subjects: subjects,
      rooms: rooms,
      facultyAvailability: availability,
      entries: [],
      createdAt: DateTime.now(),
    );
  }
}
