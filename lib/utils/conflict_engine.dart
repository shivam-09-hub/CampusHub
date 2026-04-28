import '../models/models.dart';

class ConflictResult {
  final String
      type; // faculty, room, class, duplicate, availability, maxLectures
  final String severity; // error, warning
  final String message;
  final int? day;
  final int? slot;
  final String? entity;

  const ConflictResult({
    required this.type,
    required this.severity,
    required this.message,
    this.day,
    this.slot,
    this.entity,
  });
}

class SlotSuggestion {
  final int day;
  final int slot;

  const SlotSuggestion(this.day, this.slot);

  String get label => '${ConflictEngine.dayName(day)} Slot ${slot + 1}';
}

class ConflictEngine {
  static List<ConflictResult> analyzeGlobal({
    required List<TimetableProject> existingTimetables,
    required List<TimetableEntry> newEntries,
    required String newClassName,
    required int workingDays,
    required List<TimeSlotDef> timeSlots,
    Map<String, int>? facultyMaxLectures,
    Map<String, FacultyAvailability>? facultyAvailability,
  }) {
    final results = <ConflictResult>[];
    final globalFaculty = <String, Set<String>>{};
    final globalRoom = <String, Set<String>>{};
    final globalClass = <String, Set<String>>{};
    final globalFacultyDayCount = <String, Map<int, int>>{};

    for (final project in existingTimetables) {
      for (final entry in project.entries) {
        if (entry.isBreak) continue;
        final slotKey = _slotKey(entry.day, entry.slot);
        _addSlot(globalFaculty, entry.facultyName, slotKey);
        _addSlot(globalRoom, entry.roomId, slotKey);
        _addSlot(globalClass, project.className, slotKey);
        globalFacultyDayCount
            .putIfAbsent(entry.facultyName, () => {})
            .update(entry.day, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final newFacultyDayCount = <String, Map<int, int>>{};
    for (final entry in newEntries) {
      if (entry.isBreak) continue;

      if (entry.day < 0 || entry.day >= workingDays) {
        results.add(ConflictResult(
          type: 'class',
          severity: 'error',
          message:
              '"${entry.subjectName}" is outside the configured working days.',
          day: entry.day,
          slot: entry.slot,
          entity: newClassName,
        ));
        continue;
      }

      if (entry.slot < 0 || entry.slot >= timeSlots.length) {
        results.add(ConflictResult(
          type: 'class',
          severity: 'error',
          message: '"${entry.subjectName}" is outside the configured slots.',
          day: entry.day,
          slot: entry.slot,
          entity: newClassName,
        ));
        continue;
      }

      if (timeSlots[entry.slot].isBreak) {
        results.add(ConflictResult(
          type: 'class',
          severity: 'error',
          message:
              'Cannot schedule "${entry.subjectName}" during break on ${dayName(entry.day)} Slot ${entry.slot + 1}.',
          day: entry.day,
          slot: entry.slot,
          entity: newClassName,
        ));
      }

      final slotKey = _slotKey(entry.day, entry.slot);
      if (globalFaculty[entry.facultyName]?.contains(slotKey) == true) {
        results.add(ConflictResult(
          type: 'faculty',
          severity: 'error',
          message:
              'Faculty "${entry.facultyName}" is already teaching on ${dayName(entry.day)} Slot ${entry.slot + 1}.',
          day: entry.day,
          slot: entry.slot,
          entity: entry.facultyName,
        ));
      }

      if (entry.roomId.isNotEmpty &&
          globalRoom[entry.roomId]?.contains(slotKey) == true) {
        results.add(ConflictResult(
          type: 'room',
          severity: 'error',
          message:
              'Room "${entry.roomId}" is already occupied on ${dayName(entry.day)} Slot ${entry.slot + 1}.',
          day: entry.day,
          slot: entry.slot,
          entity: entry.roomId,
        ));
      }

      if (globalClass[newClassName]?.contains(slotKey) == true) {
        results.add(ConflictResult(
          type: 'class',
          severity: 'error',
          message:
              'Class "$newClassName" already has a lecture on ${dayName(entry.day)} Slot ${entry.slot + 1}.',
          day: entry.day,
          slot: entry.slot,
          entity: newClassName,
        ));
      }

      final availability = facultyAvailability?[entry.facultyName];
      if (availability != null) {
        final unavailableDay = availability.availableDays.isNotEmpty &&
            !availability.availableDays.contains(entry.day);
        final unavailableSlot = availability.availableSlots.isNotEmpty &&
            !availability.availableSlots.contains(entry.slot);
        if (unavailableDay || unavailableSlot) {
          results.add(ConflictResult(
            type: 'availability',
            severity: 'error',
            message:
                'Faculty "${entry.facultyName}" is unavailable on ${dayName(entry.day)} Slot ${entry.slot + 1}.',
            day: entry.day,
            slot: entry.slot,
            entity: entry.facultyName,
          ));
        }
      }

      newFacultyDayCount
          .putIfAbsent(entry.facultyName, () => {})
          .update(entry.day, (count) => count + 1, ifAbsent: () => 1);
    }

    results.addAll(_checkInternalConflicts(newEntries, newClassName));
    results.addAll(_checkFacultyDailyLoads(
      newFacultyDayCount: newFacultyDayCount,
      globalFacultyDayCount: globalFacultyDayCount,
      facultyMaxLectures: facultyMaxLectures,
    ));

    return results;
  }

  static List<ConflictResult> checkSlotAvailability({
    required String facultyName,
    required String roomId,
    required int day,
    required int slot,
    required List<TimetableProject> existingTimetables,
    required List<TimetableEntry> currentEntries,
    String? className,
    String? excludeProjectId,
    int? ignoreDay,
    int? ignoreSlot,
  }) {
    final results = <ConflictResult>[];

    for (final project in existingTimetables) {
      if (project.id == excludeProjectId) continue;
      for (final entry in project.entries) {
        if (entry.day != day || entry.slot != slot || entry.isBreak) continue;
        if (entry.facultyName == facultyName) {
          results.add(ConflictResult(
            type: 'faculty',
            severity: 'error',
            message:
                'Faculty "$facultyName" teaches "${entry.subjectName}" in ${project.className}.',
            day: day,
            slot: slot,
            entity: facultyName,
          ));
        }
        if (entry.roomId == roomId) {
          results.add(ConflictResult(
            type: 'room',
            severity: 'error',
            message:
                'Room "$roomId" is used for "${entry.subjectName}" in ${project.className}.',
            day: day,
            slot: slot,
            entity: roomId,
          ));
        }
        if (className != null && project.className == className) {
          results.add(ConflictResult(
            type: 'class',
            severity: 'error',
            message:
                'Class "$className" already has "${entry.subjectName}" in this slot.',
            day: day,
            slot: slot,
            entity: className,
          ));
        }
      }
    }

    for (final entry in currentEntries) {
      if (entry.day == ignoreDay && entry.slot == ignoreSlot) continue;
      if (entry.day != day || entry.slot != slot || entry.isBreak) continue;
      results.add(ConflictResult(
        type: 'class',
        severity: 'error',
        message: 'This class already has "${entry.subjectName}" in this slot.',
        day: day,
        slot: slot,
        entity: className,
      ));
      if (entry.facultyName == facultyName) {
        results.add(ConflictResult(
          type: 'faculty',
          severity: 'error',
          message: 'Faculty "$facultyName" already has a lecture here.',
          day: day,
          slot: slot,
          entity: facultyName,
        ));
      }
      if (entry.roomId == roomId) {
        results.add(ConflictResult(
          type: 'room',
          severity: 'error',
          message: 'Room "$roomId" already has a lecture here.',
          day: day,
          slot: slot,
          entity: roomId,
        ));
      }
    }

    return results;
  }

  static List<SlotSuggestion> findFreeSlots({
    required String facultyName,
    required String roomId,
    required int workingDays,
    required List<TimeSlotDef> timeSlots,
    required List<TimetableProject> existingTimetables,
    required List<TimetableEntry> currentEntries,
    String? className,
    String? excludeProjectId,
    int? ignoreDay,
    int? ignoreSlot,
    int limit = 5,
  }) {
    final free = <SlotSuggestion>[];
    for (int day = 0; day < workingDays; day++) {
      for (int slot = 0; slot < timeSlots.length; slot++) {
        if (timeSlots[slot].isBreak) continue;
        final conflicts = checkSlotAvailability(
          facultyName: facultyName,
          roomId: roomId,
          day: day,
          slot: slot,
          existingTimetables: existingTimetables,
          currentEntries: currentEntries,
          className: className,
          excludeProjectId: excludeProjectId,
          ignoreDay: ignoreDay,
          ignoreSlot: ignoreSlot,
        );
        if (conflicts.isEmpty) {
          free.add(SlotSuggestion(day, slot));
          if (free.length >= limit) return free;
        }
      }
    }
    return free;
  }

  static Map<String, dynamic> generateReport({
    required TimetableProject project,
    required List<TimetableProject> allTimetables,
    Map<String, int>? facultyMaxLectures,
  }) {
    final otherTimetables =
        allTimetables.where((timetable) => timetable.id != project.id).toList();
    final conflicts = analyzeGlobal(
      existingTimetables: otherTimetables,
      newEntries: project.entries,
      newClassName: project.className,
      workingDays: project.workingDays,
      timeSlots: project.timeSlots,
      facultyMaxLectures: facultyMaxLectures,
    );

    final errors =
        conflicts.where((conflict) => conflict.severity == 'error').length;
    final warnings =
        conflicts.where((conflict) => conflict.severity == 'warning').length;

    return {
      'totalEntries': project.entries.where((entry) => !entry.isBreak).length,
      'errors': errors,
      'warnings': warnings,
      'conflicts': conflicts,
      'isClean': errors == 0,
    };
  }

  static bool hasErrors(List<ConflictResult> conflicts) =>
      conflicts.any((conflict) => conflict.severity == 'error');

  static String dayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return day >= 0 && day < days.length ? days[day] : 'Day ${day + 1}';
  }

  static List<ConflictResult> _checkInternalConflicts(
    List<TimetableEntry> entries,
    String className,
  ) {
    final results = <ConflictResult>[];
    final classSlots = <String, TimetableEntry>{};
    final facultySlots = <String, TimetableEntry>{};
    final roomSlots = <String, TimetableEntry>{};
    final allocationKeys = <String>{};

    for (final entry in entries) {
      if (entry.isBreak) continue;
      final slotKey = _slotKey(entry.day, entry.slot);
      final classEntry = classSlots[slotKey];
      if (classEntry != null) {
        results.add(ConflictResult(
          type: 'class',
          severity: 'error',
          message:
              'Class "$className" has both "${classEntry.subjectName}" and "${entry.subjectName}" on ${dayName(entry.day)} Slot ${entry.slot + 1}.',
          day: entry.day,
          slot: entry.slot,
          entity: className,
        ));
      } else {
        classSlots[slotKey] = entry;
      }

      final facultyKey = '${entry.facultyName}|$slotKey';
      final facultyEntry = facultySlots[facultyKey];
      if (facultyEntry != null) {
        results.add(ConflictResult(
          type: 'faculty',
          severity: 'error',
          message:
              'Faculty "${entry.facultyName}" is double-booked for "${facultyEntry.subjectName}" and "${entry.subjectName}".',
          day: entry.day,
          slot: entry.slot,
          entity: entry.facultyName,
        ));
      } else {
        facultySlots[facultyKey] = entry;
      }

      final roomKey = '${entry.roomId}|$slotKey';
      final roomEntry = roomSlots[roomKey];
      if (entry.roomId.isNotEmpty && roomEntry != null) {
        results.add(ConflictResult(
          type: 'room',
          severity: 'error',
          message:
              'Room "${entry.roomId}" is double-booked for "${roomEntry.subjectName}" and "${entry.subjectName}".',
          day: entry.day,
          slot: entry.slot,
          entity: entry.roomId,
        ));
      } else {
        roomSlots[roomKey] = entry;
      }

      final allocationKey =
          '${entry.subjectName}|${entry.facultyName}|${entry.roomId}|$slotKey';
      if (!allocationKeys.add(allocationKey)) {
        results.add(ConflictResult(
          type: 'duplicate',
          severity: 'error',
          message:
              'Duplicate allocation found for "${entry.subjectName}" on ${dayName(entry.day)} Slot ${entry.slot + 1}.',
          day: entry.day,
          slot: entry.slot,
          entity: entry.subjectName,
        ));
      }
    }

    return results;
  }

  static List<ConflictResult> _checkFacultyDailyLoads({
    required Map<String, Map<int, int>> newFacultyDayCount,
    required Map<String, Map<int, int>> globalFacultyDayCount,
    Map<String, int>? facultyMaxLectures,
  }) {
    if (facultyMaxLectures == null) return const [];

    final results = <ConflictResult>[];
    for (final facultyEntry in newFacultyDayCount.entries) {
      final facultyName = facultyEntry.key;
      final maxAllowed = facultyMaxLectures[facultyName] ?? 6;
      for (final dayEntry in facultyEntry.value.entries) {
        final existingCount =
            globalFacultyDayCount[facultyName]?[dayEntry.key] ?? 0;
        final totalCount = existingCount + dayEntry.value;
        if (totalCount > maxAllowed) {
          results.add(ConflictResult(
            type: 'maxLectures',
            severity: 'warning',
            message:
                'Faculty "$facultyName" has $totalCount lectures on ${dayName(dayEntry.key)}. Max allowed is $maxAllowed.',
            day: dayEntry.key,
            entity: facultyName,
          ));
        }
      }
    }
    return results;
  }

  static void _addSlot(
      Map<String, Set<String>> map, String entity, String slot) {
    if (entity.isEmpty) return;
    map.putIfAbsent(entity, () => {}).add(slot);
  }

  static String _slotKey(int day, int slot) => '$day:$slot';
}
