// ─── Models ───────────────────────────────────────────────────────────────────

import '../utils/model_serializers.dart';

class SubjectModel {
  String id;
  String name;
  String facultyName;
  int hoursPerWeek;
  int colorIndex;
  String subjectType; // Theory, Lab, Tutorial

  SubjectModel({
    required this.id,
    required this.name,
    required this.facultyName,
    required this.hoursPerWeek,
    this.colorIndex = 0,
    this.subjectType = 'Theory',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'facultyName': facultyName,
        'hoursPerWeek': hoursPerWeek,
        'colorIndex': colorIndex,
        'subjectType': subjectType,
      };

  factory SubjectModel.fromMap(Map<String, dynamic> m) => SubjectModel(
        id: m['id'],
        name: m['name'],
        facultyName: m['facultyName'],
        hoursPerWeek: m['hoursPerWeek'] ?? m['hours_per_week'] ?? 3,
        colorIndex: m['colorIndex'] ?? 0,
        subjectType: m['subjectType'] ?? m['subject_type'] ?? 'Theory',
      );
}

class RoomModel {
  String id;
  String roomId;
  int capacity;
  String roomType; // Classroom, Lab, Seminar Hall

  RoomModel(
      {required this.id,
      required this.roomId,
      required this.capacity,
      this.roomType = 'Classroom'});

  Map<String, dynamic> toMap() => {
        'id': id,
        'room_id': roomId,
        'capacity': capacity,
        'room_type': roomType
      };

  factory RoomModel.fromMap(Map<String, dynamic> m) => RoomModel(
        id: m['id'],
        roomId: m['room_id'] ?? m['roomId'],
        capacity: m['capacity'] ?? 40,
        roomType: m['room_type'] ?? m['roomType'] ?? 'Classroom',
      );
}

class FacultyAvailability {
  String facultyName;
  List<int> availableDays; // 0-indexed
  List<int> availableSlots; // 0-indexed

  FacultyAvailability({
    required this.facultyName,
    required this.availableDays,
    required this.availableSlots,
  });

  Map<String, dynamic> toMap() => {
        'facultyName': facultyName,
        'availableDays': availableDays,
        'availableSlots': availableSlots,
      };

  factory FacultyAvailability.fromMap(Map<String, dynamic> m) =>
      FacultyAvailability(
        facultyName: m['facultyName'],
        availableDays: List<int>.from(m['availableDays']),
        availableSlots: List<int>.from(m['availableSlots']),
      );
}

class TimetableEntry {
  String subjectName;
  String facultyName;
  String roomId;
  int day;
  int slot;
  String startTime;
  String endTime;
  bool isBreak;
  String breakName;
  bool hasConflict;

  TimetableEntry({
    required this.subjectName,
    required this.facultyName,
    required this.roomId,
    required this.day,
    required this.slot,
    this.startTime = '',
    this.endTime = '',
    this.isBreak = false,
    this.breakName = '',
    this.hasConflict = false,
  });

  Map<String, dynamic> toMap() => {
        'subjectName': subjectName,
        'facultyName': facultyName,
        'roomId': roomId,
        'day': day,
        'slot': slot,
        'startTime': startTime,
        'endTime': endTime,
        'isBreak': isBreak,
        'breakName': breakName,
        'hasConflict': hasConflict,
      };

  factory TimetableEntry.fromMap(Map<String, dynamic> m) => TimetableEntry(
        subjectName: m['subjectName'] ?? '',
        facultyName: m['facultyName'] ?? '',
        roomId: m['roomId'] ?? '',
        day: m['day'] ?? 0,
        slot: m['slot'] ?? 0,
        startTime: m['startTime'] ?? '',
        endTime: m['endTime'] ?? '',
        isBreak: m['isBreak'] ?? false,
        breakName: m['breakName'] ?? '',
        hasConflict: m['hasConflict'] ?? false,
      );
}

/// Represents a time slot definition for the timetable
class TimeSlotDef {
  String startTime;
  String endTime;
  bool isBreak;
  String breakName;

  TimeSlotDef({
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
    this.breakName = '',
  });

  Map<String, dynamic> toMap() => {
        'startTime': startTime,
        'endTime': endTime,
        'isBreak': isBreak,
        'breakName': breakName,
      };

  factory TimeSlotDef.fromMap(Map<String, dynamic> m) => TimeSlotDef(
        startTime: m['startTime'] ?? '',
        endTime: m['endTime'] ?? '',
        isBreak: m['isBreak'] ?? false,
        breakName: m['breakName'] ?? '',
      );

  String get label => isBreak
      ? (breakName.isNotEmpty ? breakName : 'Break')
      : '$startTime - $endTime';
}

class TimetableProject {
  String id;
  String className;
  int workingDays;
  int slotsPerDay;
  List<SubjectModel> subjects;
  List<RoomModel> rooms;
  List<FacultyAvailability> facultyAvailability;
  List<TimetableEntry> entries;
  List<TimeSlotDef> timeSlots;
  DateTime createdAt;
  String department;
  String semester;
  bool published;
  String? createdBy;

  TimetableProject({
    required this.id,
    required this.className,
    required this.workingDays,
    required this.slotsPerDay,
    required this.subjects,
    required this.rooms,
    required this.facultyAvailability,
    required this.entries,
    required this.createdAt,
    this.timeSlots = const [],
    this.department = '',
    this.semester = '',
    this.published = false,
    this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'class_name': className,
        'working_days': workingDays,
        'slots_per_day': slotsPerDay,
        'subjects': subjects.map((s) => s.toMap()).toList(),
        'rooms': rooms.map((r) => r.toMap()).toList(),
        'faculty_availability':
            facultyAvailability.map((f) => f.toMap()).toList(),
        'entries': entries.map((e) => e.toMap()).toList(),
        'time_slots': timeSlots.map((t) => t.toMap()).toList(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'department': department,
        'semester': semester,
        'published': published,
        'created_by': createdBy,
      };

  factory TimetableProject.fromMap(Map<String, dynamic> m) => TimetableProject(
        id: m['id'],
        className: m['class_name'] ?? m['className'],
        workingDays: m['working_days'] ?? m['workingDays'],
        slotsPerDay: m['slots_per_day'] ?? m['slotsPerDay'],
        subjects: listFromJsonValue(m['subjects'], SubjectModel.fromMap),
        rooms: listFromJsonValue(m['rooms'], RoomModel.fromMap),
        facultyAvailability: listFromJsonValue(
          m['faculty_availability'] ?? m['facultyAvailability'],
          FacultyAvailability.fromMap,
        ),
        entries: listFromJsonValue(m['entries'], TimetableEntry.fromMap),
        timeSlots: listFromJsonValue(
          m['time_slots'] ?? m['timeSlots'],
          TimeSlotDef.fromMap,
        ),
        createdAt: dateTimeFromMapValue(m['created_at'] ?? m['createdAt']),
        department: m['department'] ?? '',
        semester: m['semester'] ?? '',
        published: m['published'] ?? false,
        createdBy: m['created_by'] ?? m['createdBy'],
      );
}
