import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class ExcelExporter {
  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];

  static Future<String> export(TimetableProject project) async {
    final excel = Excel.createExcel();
    final sheet = excel['Timetable'];

    // Remove default sheet if different
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4A6CF7'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Break slot header style
    final breakHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFA000'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Break cell style
    final breakCellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFF8E1'),
      fontColorHex: ExcelColor.fromHexString('#F57F17'),
      horizontalAlign: HorizontalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    // First cell
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('Day / Time Slot')
      ..cellStyle = headerStyle;

    // Column headers with time slot info
    for (int s = 0; s < project.slotsPerDay; s++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: s + 1, rowIndex: 0));

      if (s < project.timeSlots.length) {
        final ts = project.timeSlots[s];
        if (ts.isBreak) {
          final breakName = ts.breakName.isNotEmpty ? ts.breakName : 'Break';
          cell.value = TextCellValue('$breakName\n${ts.startTime}-${ts.endTime}');
          cell.cellStyle = breakHeaderStyle;
        } else {
          cell.value = TextCellValue('Slot ${s + 1}\n${ts.startTime}-${ts.endTime}');
          cell.cellStyle = headerStyle;
        }
      } else {
        cell.value = TextCellValue('Slot ${s + 1}');
        cell.cellStyle = headerStyle;
      }
    }

    // Day rows
    final dayStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E8ECFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (int d = 0; d < project.workingDays; d++) {
      final dayName = d < _dayNames.length ? _dayNames[d] : 'Day ${d + 1}';
      final dayCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: d + 1));
      dayCell.value = TextCellValue(dayName);
      dayCell.cellStyle = dayStyle;

      for (int s = 0; s < project.slotsPerDay; s++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: s + 1, rowIndex: d + 1));

        // Check if this is a break slot
        if (s < project.timeSlots.length && project.timeSlots[s].isBreak) {
          final breakName = project.timeSlots[s].breakName.isNotEmpty
              ? project.timeSlots[s].breakName
              : 'Break';
          cell.value = TextCellValue('☕ $breakName');
          cell.cellStyle = breakCellStyle;
          continue;
        }

        final entry = project.entries.firstWhere(
          (e) => e.day == d && e.slot == s,
          orElse: () => TimetableEntry(
              subjectName: '', facultyName: '', roomId: '', day: d, slot: s),
        );

        if (entry.subjectName.isEmpty) {
          cell.value = TextCellValue('---');
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#F9F9F9'),
          );
        } else {
          cell.value = TextCellValue(
              '${entry.subjectName}\n${entry.facultyName}\n[${entry.roomId}]');
          cell.cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: ExcelColor.fromHexString('#EEF1FF'),
            textWrapping: TextWrapping.WrapText,
          );
        }
      }
    }

    // Auto-width columns
    for (int c = 0; c <= project.slotsPerDay; c++) {
      sheet.setColumnWidth(c, c == 0 ? 14 : 22);
    }

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final sanitized = project.className.replaceAll(RegExp(r'[^\w\s]'), '_');
    final filename = 'Timetable_${sanitized}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${dir.path}/$filename');
    final bytes = excel.save();
    if (bytes == null) throw Exception('Failed to generate Excel file');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Export AND share the file
  static Future<void> exportAndShare(TimetableProject project) async {
    final filePath = await export(project);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '${project.className} Timetable',
      text: 'Timetable for ${project.className} - ${project.department} Sem ${project.semester}',
    );
  }
}
