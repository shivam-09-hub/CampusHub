import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class PdfExporter {
  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];

  // Subject colors for PDF (PdfColors)
  static const List<PdfColor> _subjectBgColors = [
    PdfColor.fromInt(0xFFE3EAFF), // blue
    PdfColor.fromInt(0xFFFFE8E3), // orange
    PdfColor.fromInt(0xFFE3FFE8), // green
    PdfColor.fromInt(0xFFFFF3E3), // yellow
    PdfColor.fromInt(0xFFF3E3FF), // purple
    PdfColor.fromInt(0xFFE3FFF8), // teal
    PdfColor.fromInt(0xFFFFE3F3), // pink
    PdfColor.fromInt(0xFFE3F8FF), // cyan
  ];

  static const List<PdfColor> _subjectAccentColors = [
    PdfColor.fromInt(0xFF4A6CF7),
    PdfColor.fromInt(0xFFFF6B4A),
    PdfColor.fromInt(0xFF4AE36B),
    PdfColor.fromInt(0xFFFFB84A),
    PdfColor.fromInt(0xFFB84AF7),
    PdfColor.fromInt(0xFF4AF7D6),
    PdfColor.fromInt(0xFFF74AA8),
    PdfColor.fromInt(0xFF4AC8F7),
  ];

  static const _breakBg = PdfColor.fromInt(0xFFFFF8E1);
  static const _breakAccent = PdfColor.fromInt(0xFFFFA000);

  /// Generate a PDF and return the file path
  static Future<String> export(TimetableProject project) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.interRegular(),
        bold: await PdfGoogleFonts.interBold(),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(project),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildTimetableTable(project),
          pw.SizedBox(height: 20),
          _buildLegend(project),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Generated on ${DateTime.now().toString().split('.').first}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ),
    );

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final sanitized = project.className.replaceAll(RegExp(r'[^\w\s]'), '_');
    final filename =
        'Timetable_${sanitized}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$filename');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Print or share the PDF
  static Future<void> printPdf(TimetableProject project) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.interRegular(),
        bold: await PdfGoogleFonts.interBold(),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(project),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildTimetableTable(project),
          pw.SizedBox(height: 20),
          _buildLegend(project),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Generated on ${DateTime.now().toString().split('.').first}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${project.className} Timetable',
    );
  }

  /// Share the PDF via share_plus
  static Future<void> sharePdf(TimetableProject project) async {
    final filePath = await export(project);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '${project.className} Timetable',
      text: 'Timetable for ${project.className} - ${project.department} Sem ${project.semester}',
    );
  }

  static pw.Widget _buildHeader(TimetableProject project) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF4A6CF7),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                project.className,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${project.department} • Semester ${project.semester}',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'CampusHub ERP',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                '${project.workingDays} Days • ${project.slotsPerDay} Slots',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _slotLabel(TimetableProject project, int slot) {
    if (slot < project.timeSlots.length) {
      final ts = project.timeSlots[slot];
      if (ts.isBreak) return ts.breakName.isNotEmpty ? ts.breakName : 'Break';
      return '${ts.startTime}\n${ts.endTime}';
    }
    return 'Slot ${slot + 1}';
  }

  static pw.Widget _buildTimetableTable(TimetableProject project) {
    final headerStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // Build table data
    final List<pw.TableRow> rows = [];

    // Header row
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF4A6CF7),
      ),
      children: [
        _tableHeaderCell('Day / Time', headerStyle),
        ...List.generate(
            project.slotsPerDay, (s) => _tableHeaderCell(_slotLabel(project, s), headerStyle)),
      ],
    ));

    // Data rows
    for (int d = 0; d < project.workingDays; d++) {
      final dayName = d < _dayNames.length ? _dayNames[d] : 'Day ${d + 1}';
      rows.add(pw.TableRow(
        children: [
          // Day label
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE8ECFF),
            ),
            child: pw.Text(
              dayName.substring(0, 3).toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF4A6CF7),
              ),
            ),
          ),
          // Slot cells
          ...List.generate(project.slotsPerDay, (s) {
            // Check if this is a break slot
            if (s < project.timeSlots.length && project.timeSlots[s].isBreak) {
              return _breakCell(project.timeSlots[s]);
            }

            final entry = project.entries
                .where((e) => e.day == d && e.slot == s)
                .firstOrNull;

            if (entry == null) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF9F9F9),
                ),
                child: pw.Center(
                  child: pw.Text('—',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey400,
                      )),
                ),
              );
            }

            final ci = project.subjects
                .firstWhere((su) => su.name == entry.subjectName,
                    orElse: () => SubjectModel(
                        id: '', name: '', facultyName: '', hoursPerWeek: 0))
                .colorIndex;
            final bg = _subjectBgColors[ci % _subjectBgColors.length];
            final accent = _subjectAccentColors[ci % _subjectAccentColors.length];

            return pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(color: bg),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(entry.subjectName,
                      textAlign: pw.TextAlign.center,
                      maxLines: 2,
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      )),
                  pw.SizedBox(height: 2),
                  pw.Text(entry.facultyName,
                      textAlign: pw.TextAlign.center,
                      maxLines: 1,
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey700,
                      )),
                  pw.Text('[${entry.roomId}]',
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey500,
                      )),
                ],
              ),
            );
          }),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        for (int i = 1; i <= project.slotsPerDay; i++)
          i: const pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static pw.Widget _tableHeaderCell(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, textAlign: pw.TextAlign.center, style: style),
    );
  }

  static pw.Widget _breakCell(TimeSlotDef slot) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: const pw.BoxDecoration(color: _breakBg),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('☕',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text(
            slot.breakName.isNotEmpty ? slot.breakName : 'Break',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: _breakAccent,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLegend(TimetableProject project) {
    final subjects = project.subjects;
    if (subjects.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8F9FF),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Subject Legend',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 16,
            runSpacing: 6,
            children: subjects.map((s) {
              final accent =
                  _subjectAccentColors[s.colorIndex % _subjectAccentColors.length];
              final bg =
                  _subjectBgColors[s.colorIndex % _subjectBgColors.length];
              return pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: bg,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text('${s.name} (${s.facultyName})',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                    )),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
