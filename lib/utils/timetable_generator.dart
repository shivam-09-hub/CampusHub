import '../models/models.dart';

class TimetableGenerator {
  static (List<TimetableEntry>, List<String>) generate({
    required int workingDays,
    required List<TimeSlotDef> timeSlots,
    required List<SubjectModel> subjects,
    required List<RoomModel> rooms,
    required List<FacultyAvailability> facultyAvailability,
    List<TimetableProject> existingTimetables = const [],
    Map<String, int>? facultyMaxLectures,
    String? className,
    String? excludeProjectId,
  }) {
    final entries = <TimetableEntry>[];
    final messages = <String>[];

    final globalFacultyOccupied = <String, Set<String>>{};
    final globalRoomOccupied = <String, Set<String>>{};
    final globalClassOccupied = <String, Set<String>>{};
    final globalFacultyDayCount = <String, Map<int, int>>{};

    for (final project in existingTimetables) {
      if (project.id == excludeProjectId) continue;
      for (final entry in project.entries) {
        if (entry.isBreak) continue;
        final slotKey = _slotKey(entry.day, entry.slot);
        _addSlot(globalFacultyOccupied, entry.facultyName, slotKey);
        _addSlot(globalRoomOccupied, entry.roomId, slotKey);
        _addSlot(globalClassOccupied, project.className, slotKey);
        globalFacultyDayCount
            .putIfAbsent(entry.facultyName, () => {})
            .update(entry.day, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final availabilityByFaculty = {
      for (final item in facultyAvailability) item.facultyName: item,
    };
    final localClassOccupied = <String>{};
    final localFacultyOccupied = <String, Set<String>>{};
    final localRoomOccupied = <String, Set<String>>{};
    final localFacultyDayCount = <String, Map<int, int>>{};
    final subjectDayCount = <String, Map<int, int>>{};

    final teachingSlots = <({int day, int slot})>[
      for (int day = 0; day < workingDays; day++)
        for (int slot = 0; slot < timeSlots.length; slot++)
          if (!timeSlots[slot].isBreak) (day: day, slot: slot),
    ];

    final sessions = <SubjectModel>[];
    for (final subject in subjects) {
      for (int i = 0; i < subject.hoursPerWeek; i++) {
        sessions.add(subject);
      }
    }
    sessions.sort((a, b) {
      final typeCompare =
          _typeWeight(b.subjectType).compareTo(_typeWeight(a.subjectType));
      if (typeCompare != 0) return typeCompare;
      return b.hoursPerWeek.compareTo(a.hoursPerWeek);
    });

    int placed = 0;
    int avoided = 0;
    final unplaced = <String, int>{};

    for (final session in sessions) {
      final facultyName = session.facultyName.trim();
      final maxPerDay = facultyMaxLectures?[facultyName] ?? 6;
      final availability = availabilityByFaculty[facultyName];

      final candidates = teachingSlots.where((candidate) {
        final day = candidate.day;
        final slot = candidate.slot;
        final slotKey = _slotKey(day, slot);

        if (className != null &&
            globalClassOccupied[className]?.contains(slotKey) == true) {
          avoided++;
          return false;
        }
        if (localClassOccupied.contains(slotKey)) return false;
        if (globalFacultyOccupied[facultyName]?.contains(slotKey) == true) {
          avoided++;
          return false;
        }
        if (localFacultyOccupied[facultyName]?.contains(slotKey) == true) {
          return false;
        }
        if (availability != null) {
          if (availability.availableDays.isNotEmpty &&
              !availability.availableDays.contains(day)) {
            return false;
          }
          if (availability.availableSlots.isNotEmpty &&
              !availability.availableSlots.contains(slot)) {
            return false;
          }
        }
        final lecturesToday = (globalFacultyDayCount[facultyName]?[day] ?? 0) +
            (localFacultyDayCount[facultyName]?[day] ?? 0);
        return lecturesToday < maxPerDay;
      }).toList();

      candidates.sort((a, b) {
        final subjectADay = subjectDayCount[session.name]?[a.day] ?? 0;
        final subjectBDay = subjectDayCount[session.name]?[b.day] ?? 0;
        if (subjectADay != subjectBDay) {
          return subjectADay.compareTo(subjectBDay);
        }

        final facultyADay = (globalFacultyDayCount[facultyName]?[a.day] ?? 0) +
            (localFacultyDayCount[facultyName]?[a.day] ?? 0);
        final facultyBDay = (globalFacultyDayCount[facultyName]?[b.day] ?? 0) +
            (localFacultyDayCount[facultyName]?[b.day] ?? 0);
        if (facultyADay != facultyBDay) {
          return facultyADay.compareTo(facultyBDay);
        }

        return a.slot.compareTo(b.slot);
      });

      TimetableEntry? placedEntry;
      for (final candidate in candidates) {
        final room = _findFreeRoom(
          rooms: rooms,
          subjectType: session.subjectType,
          day: candidate.day,
          slot: candidate.slot,
          globalRoomOccupied: globalRoomOccupied,
          localRoomOccupied: localRoomOccupied,
        );
        if (room == null) continue;

        placedEntry = TimetableEntry(
          subjectName: session.name,
          facultyName: facultyName,
          roomId: room.roomId,
          day: candidate.day,
          slot: candidate.slot,
          startTime: timeSlots[candidate.slot].startTime,
          endTime: timeSlots[candidate.slot].endTime,
        );
        break;
      }

      if (placedEntry == null) {
        unplaced.update(session.name, (count) => count + 1, ifAbsent: () => 1);
        continue;
      }

      final slotKey = _slotKey(placedEntry.day, placedEntry.slot);
      entries.add(placedEntry);
      localClassOccupied.add(slotKey);
      _addSlot(localFacultyOccupied, facultyName, slotKey);
      _addSlot(localRoomOccupied, placedEntry.roomId, slotKey);
      localFacultyDayCount
          .putIfAbsent(facultyName, () => {})
          .update(placedEntry.day, (count) => count + 1, ifAbsent: () => 1);
      subjectDayCount
          .putIfAbsent(session.name, () => {})
          .update(placedEntry.day, (count) => count + 1, ifAbsent: () => 1);
      placed++;
    }

    if (placed > 0) {
      messages
          .add('Timetable generated successfully. $placed sessions placed.');
    }
    if (avoided > 0) {
      messages
          .add('$avoided occupied global slots were avoided automatically.');
    }
    if (unplaced.isNotEmpty) {
      for (final item in unplaced.entries) {
        messages.add(
          'Could not place ${item.value} session(s) for "${item.key}". Add slots, rooms, or faculty availability.',
        );
      }
    }
    if (entries.isEmpty) {
      messages.add('No sessions could be placed with the current constraints.');
    }

    return (entries, messages);
  }

  static RoomModel? _findFreeRoom({
    required List<RoomModel> rooms,
    required String subjectType,
    required int day,
    required int slot,
    required Map<String, Set<String>> globalRoomOccupied,
    required Map<String, Set<String>> localRoomOccupied,
  }) {
    if (rooms.isEmpty) return null;
    final preferred = _orderedRoomsForSubject(rooms, subjectType);
    final slotKey = _slotKey(day, slot);
    for (final room in preferred) {
      final globallyBusy =
          globalRoomOccupied[room.roomId]?.contains(slotKey) == true;
      final locallyBusy =
          localRoomOccupied[room.roomId]?.contains(slotKey) == true;
      if (!globallyBusy && !locallyBusy) return room;
    }
    return null;
  }

  static List<RoomModel> _orderedRoomsForSubject(
    List<RoomModel> rooms,
    String subjectType,
  ) {
    final normalizedType = subjectType.toLowerCase();
    final preferred = rooms.where((room) {
      final roomType = room.roomType.toLowerCase();
      if (normalizedType == 'lab') return roomType == 'lab';
      return roomType == 'classroom' || roomType == 'seminar hall';
    }).toList();
    final fallback = rooms.where((room) => !preferred.contains(room)).toList();
    return [...preferred, ...fallback];
  }

  static int _typeWeight(String subjectType) {
    if (subjectType.toLowerCase() == 'lab') return 3;
    if (subjectType.toLowerCase() == 'tutorial') return 2;
    return 1;
  }

  static void _addSlot(
      Map<String, Set<String>> map, String entity, String slot) {
    if (entity.isEmpty) return;
    map.putIfAbsent(entity, () => {}).add(slot);
  }

  static String _slotKey(int day, int slot) => '$day:$slot';
}
