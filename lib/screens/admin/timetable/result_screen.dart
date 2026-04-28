import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/models.dart';
import '../../../models/user_model.dart';
import '../../../config/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/timetable_generator.dart';
import '../../../utils/conflict_engine.dart';
import '../../../utils/excel_exporter.dart';
import '../../../utils/pdf_exporter.dart';
import 'wizard_screen.dart';

class ResultScreen extends StatefulWidget {
  final TimetableProject project;
  final List<String> messages;
  final UserModel user;
  const ResultScreen(
      {super.key,
      required this.project,
      required this.messages,
      required this.user});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late List<TimetableEntry> _entries;
  late TimetableProject _project;
  final _supabaseService = SupabaseService();
  List<TimetableProject> _existingTimetables = [];
  Map<String, int> _facultyMaxLectures = {};
  List<ConflictResult> _conflicts = [];
  bool _exporting = false;
  bool _checkingMove = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _entries = List.from(widget.project.entries);
    // Remove any entries placed on break slots (fix legacy data)
    _entries.removeWhere((e) =>
        e.slot < _project.timeSlots.length &&
        _project.timeSlots[e.slot].isBreak);
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMessages(widget.messages);
      _refreshConflictContext();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  TimetableProject get _currentProject => TimetableProject(
        id: _project.id,
        className: _project.className,
        workingDays: _project.workingDays,
        slotsPerDay: _project.slotsPerDay,
        subjects: _project.subjects,
        rooms: _project.rooms,
        facultyAvailability: _project.facultyAvailability,
        entries: List.from(_entries),
        timeSlots: _project.timeSlots,
        createdAt: _project.createdAt,
        department: _project.department,
        semester: _project.semester,
        published: _project.published,
        createdBy: _project.createdBy,
      );

  int _colorForSubject(String name) => _project.subjects
      .firstWhere((s) => s.name == name,
          orElse: () =>
              SubjectModel(id: '', name: '', facultyName: '', hoursPerWeek: 0))
      .colorIndex;

  bool _isBreakSlot(int slot) {
    return slot < _project.timeSlots.length && _project.timeSlots[slot].isBreak;
  }

  TimetableEntry? _entryAt(int day, int slot) {
    for (final e in _entries) {
      if (e.day == day && e.slot == slot) return e;
    }
    return null;
  }

  String _timeLabel(int slot) {
    if (slot < _project.timeSlots.length) {
      final ts = _project.timeSlots[slot];
      if (ts.isBreak) return ts.breakName.isNotEmpty ? ts.breakName : 'Break';
      return '${ts.startTime} - ${ts.endTime}';
    }
    return 'Slot ${slot + 1}';
  }

  Future<void> _refreshConflictContext() async {
    try {
      final timetables = await _supabaseService.getAllTimetablesOnce();
      final facultyMap = await _supabaseService.getFacultyMap();
      if (!mounted) return;
      setState(() {
        _existingTimetables = timetables;
        _facultyMaxLectures = {
          for (final entry in facultyMap.entries)
            entry.key: entry.value.maxLecturesPerDay,
        };
        _recalculateConflicts();
      });
    } catch (_) {
      if (mounted) _recalculateConflicts();
    }
  }

  void _recalculateConflicts({List<TimetableEntry>? proposedEntries}) {
    final entries = proposedEntries ?? _entries;
    final conflicts = ConflictEngine.analyzeGlobal(
      existingTimetables: _existingTimetables
          .where((timetable) => timetable.id != _project.id)
          .toList(),
      newEntries: entries,
      newClassName: _project.className,
      workingDays: _project.workingDays,
      timeSlots: _project.timeSlots,
      facultyMaxLectures: _facultyMaxLectures,
      facultyAvailability: {
        for (final item in _project.facultyAvailability) item.facultyName: item,
      },
    );

    if (proposedEntries == null) {
      for (final entry in _entries) {
        entry.hasConflict = conflicts.any((conflict) =>
            conflict.severity == 'error' &&
            conflict.day == entry.day &&
            conflict.slot == entry.slot);
      }
      _conflicts = conflicts;
    }
  }

  TimetableEntry _copyEntryAt(TimetableEntry entry, int day, int slot) {
    final timeSlot = slot < _project.timeSlots.length
        ? _project.timeSlots[slot]
        : TimeSlotDef(startTime: entry.startTime, endTime: entry.endTime);
    return TimetableEntry(
      subjectName: entry.subjectName,
      facultyName: entry.facultyName,
      roomId: entry.roomId,
      day: day,
      slot: slot,
      startTime: timeSlot.startTime,
      endTime: timeSlot.endTime,
      isBreak: entry.isBreak,
      breakName: entry.breakName,
      hasConflict: false,
    );
  }

  List<TimetableEntry> _proposedMove(
      int fromDay, int fromSlot, int toDay, int toSlot) {
    final next = List<TimetableEntry>.from(_entries);
    final fromIndex = next
        .indexWhere((entry) => entry.day == fromDay && entry.slot == fromSlot);
    final toIndex =
        next.indexWhere((entry) => entry.day == toDay && entry.slot == toSlot);
    if (fromIndex == -1) return next;

    final moving = next[fromIndex];
    if (toIndex != -1) {
      final target = next[toIndex];
      next[fromIndex] = _copyEntryAt(target, fromDay, fromSlot);
      next[toIndex] = _copyEntryAt(moving, toDay, toSlot);
    } else {
      next[fromIndex] = _copyEntryAt(moving, toDay, toSlot);
    }
    return next;
  }

  void _showMessages(List<String> msgs) {
    for (final msg in msgs) {
      final lower = msg.toLowerCase();
      final isSuccess = lower.contains('success') ||
          lower.contains('regenerated') ||
          lower.contains('placed');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isSuccess ? AppTheme.success : AppTheme.warning));
    }
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color ?? AppTheme.success,
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _handleSwap(int fd, int fs, int td, int ts) async {
    if (fd == td && fs == ts) return;
    // Prevent swapping into break slots
    if (_isBreakSlot(ts) || _isBreakSlot(fs)) {
      _snack('Cannot move classes into break/recess slots',
          color: AppTheme.error);
      return;
    }
    if (_checkingMove) return;
    HapticFeedback.lightImpact();
    setState(() => _checkingMove = true);

    final movingEntry = _entryAt(fd, fs);
    final proposedEntries = _proposedMove(fd, fs, td, ts);
    final proposedConflicts = ConflictEngine.analyzeGlobal(
      existingTimetables: _existingTimetables
          .where((timetable) => timetable.id != _project.id)
          .toList(),
      newEntries: proposedEntries,
      newClassName: _project.className,
      workingDays: _project.workingDays,
      timeSlots: _project.timeSlots,
      facultyMaxLectures: _facultyMaxLectures,
      facultyAvailability: {
        for (final item in _project.facultyAvailability) item.facultyName: item,
      },
    );
    final errors = proposedConflicts
        .where((conflict) => conflict.severity == 'error')
        .toList();
    if (errors.isNotEmpty) {
      if (!mounted) return;
      setState(() => _checkingMove = false);
      _showMoveConflicts(errors, movingEntry, fd, fs);
      return;
    }

    setState(() {
      _entries = proposedEntries;
      _recalculateConflicts();
    });
    try {
      await _supabaseService.saveTimetable(_currentProject);
      if (mounted) _snack('Moved successfully.');
    } catch (e) {
      if (mounted) {
        _snack('Move saved locally but failed online: $e',
            color: AppTheme.error);
      }
    } finally {
      if (mounted) setState(() => _checkingMove = false);
    }
  }

  void _showMoveConflicts(
    List<ConflictResult> errors,
    TimetableEntry? movingEntry,
    int fromDay,
    int fromSlot,
  ) {
    final suggestions = movingEntry == null
        ? const <SlotSuggestion>[]
        : ConflictEngine.findFreeSlots(
            facultyName: movingEntry.facultyName,
            roomId: movingEntry.roomId,
            workingDays: _project.workingDays,
            timeSlots: _project.timeSlots,
            existingTimetables: _existingTimetables,
            currentEntries: _entries,
            className: _project.className,
            excludeProjectId: _project.id,
            ignoreDay: fromDay,
            ignoreSlot: fromSlot,
          );

    _snack('Conflict detected. Move was not saved.', color: AppTheme.error);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conflict Detected'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...errors.take(3).map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error.message)),
                      ],
                    ),
                  )),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Free slots',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions
                      .map((slot) => Chip(label: Text(slot.label)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _togglePublish() async {
    final newVal = !_project.published;
    await SupabaseService().togglePublish(_project.id, newVal);
    setState(() => _project = TimetableProject(
          id: _project.id,
          className: _project.className,
          workingDays: _project.workingDays,
          slotsPerDay: _project.slotsPerDay,
          subjects: _project.subjects,
          rooms: _project.rooms,
          facultyAvailability: _project.facultyAvailability,
          entries: _entries,
          timeSlots: _project.timeSlots,
          createdAt: _project.createdAt,
          department: _project.department,
          semester: _project.semester,
          published: newVal,
          createdBy: _project.createdBy,
        ));
    _snack(newVal ? '✅ Published to students!' : 'Unpublished');
  }

  Future<void> _regenerate() async {
    await _refreshConflictContext();
    final (entries, messages) = TimetableGenerator.generate(
        workingDays: _project.workingDays,
        timeSlots: _project.timeSlots,
        subjects: _project.subjects,
        rooms: _project.rooms,
        facultyAvailability: _project.facultyAvailability,
        existingTimetables: _existingTimetables,
        facultyMaxLectures: _facultyMaxLectures,
        className: _project.className,
        excludeProjectId: _project.id);
    for (final e in entries) {
      if (e.slot < _project.timeSlots.length) {
        e.startTime = _project.timeSlots[e.slot].startTime;
        e.endTime = _project.timeSlots[e.slot].endTime;
      }
    }
    setState(() {
      _entries = entries;
      _recalculateConflicts();
    });
    await _supabaseService.saveTimetable(_currentProject);
    _showMessages(messages.isNotEmpty ? messages : ['Regenerated.']);
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      await ExcelExporter.exportAndShare(_currentProject);
      if (mounted) _snack('✅ Excel exported!');
    } catch (e) {
      if (mounted) _snack('Export failed: $e', color: AppTheme.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      await PdfExporter.sharePdf(_currentProject);
      if (mounted) _snack('✅ PDF exported!');
    } catch (e) {
      if (mounted) _snack('PDF failed: $e', color: AppTheme.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _printPdf() async {
    try {
      await PdfExporter.printPdf(_currentProject);
    } catch (e) {
      if (mounted) _snack('Print failed: $e', color: AppTheme.error);
    }
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Export & Share',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Choose export format',
              style: TextStyle(color: AppTheme.greyText, fontSize: 14)),
          const SizedBox(height: 24),
          _exportOption(
            icon: Icons.table_view,
            title: 'Export as Excel',
            subtitle: 'Share .xlsx spreadsheet file',
            color: const Color(0xFF217346),
            onTap: () {
              Navigator.pop(ctx);
              _exportExcel();
            },
          ),
          const SizedBox(height: 12),
          _exportOption(
            icon: Icons.picture_as_pdf,
            title: 'Export as PDF',
            subtitle: 'Share formatted PDF document',
            color: const Color(0xFFE53935),
            onTap: () {
              Navigator.pop(ctx);
              _exportPdf();
            },
          ),
          const SizedBox(height: 12),
          _exportOption(
            icon: Icons.print,
            title: 'Print Timetable',
            subtitle: 'Send to printer directly',
            color: AppTheme.primary,
            onTap: () {
              Navigator.pop(ctx);
              _printPdf();
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _exportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              Text(subtitle,
                  style:
                      const TextStyle(color: AppTheme.greyText, fontSize: 12)),
            ],
          )),
          Icon(Icons.chevron_right, color: color),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_project.className,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('${_project.department} • Sem ${_project.semester}',
              style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
        ]),
        actions: [
          IconButton(
              icon: Icon(
                  _project.published
                      ? Icons.cloud_done
                      : Icons.cloud_upload_outlined,
                  color: _project.published
                      ? AppTheme.success
                      : AppTheme.greyText),
              onPressed: _togglePublish,
              tooltip: _project.published ? 'Unpublish' : 'Publish'),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _regenerate,
              tooltip: 'Regenerate'),
        ],
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(icon: Icon(Icons.view_agenda_outlined), text: 'Day View'),
          Tab(icon: Icon(Icons.grid_on), text: 'Grid View')
        ]),
      ),
      body: Column(children: [
        _buildConflictBanner(),
        Expanded(
            child: TabBarView(
                controller: _tabCtrl,
                children: [_buildDayView(), _buildGridView()])),
        _buildBottomBar(),
      ]),
    );
  }

  // ── Day View ───────────────────────────────────────────────────────────────
  Widget _buildConflictBanner() {
    final errors =
        _conflicts.where((conflict) => conflict.severity == 'error').length;
    final warnings =
        _conflicts.where((conflict) => conflict.severity == 'warning').length;
    if (errors == 0 && warnings == 0 && !_checkingMove) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppTheme.success.withOpacity(0.08),
        child: const Row(children: [
          Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text('Schedule is conflict-free',
                style: TextStyle(
                    color: AppTheme.success, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: errors > 0
          ? AppTheme.error.withOpacity(0.1)
          : AppTheme.warning.withOpacity(0.12),
      child: Row(children: [
        Icon(
          _checkingMove ? Icons.sync : Icons.warning_amber_rounded,
          color: errors > 0 ? AppTheme.error : AppTheme.warning,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _checkingMove
                ? 'Checking conflicts...'
                : '$errors conflict(s), $warnings warning(s)',
            style: TextStyle(
              color: errors > 0 ? AppTheme.error : AppTheme.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDayView() {
    if (_entries.isEmpty && _project.timeSlots.every((t) => !t.isBreak)) {
      return const Center(
          child:
              Text('No entries', style: TextStyle(color: AppTheme.greyText)));
    }
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _project.workingDays,
        itemBuilder: (_, day) {
          final dayEntries = _entries.where((e) => e.day == day).toList()
            ..sort((a, b) => a.slot.compareTo(b.slot));
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(AppConst.dayLabel(day),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14))),
                      const SizedBox(width: 8),
                      Text('${dayEntries.length} classes',
                          style: const TextStyle(
                              color: AppTheme.greyText, fontSize: 13)),
                    ])),
                ...List.generate(_project.slotsPerDay, (slot) {
                  // Break slot — distinct card
                  if (_isBreakSlot(slot)) {
                    return _breakCard(slot);
                  }
                  final entry =
                      dayEntries.where((e) => e.slot == slot).firstOrNull;
                  return _dayCard(slot, entry);
                }),
                const SizedBox(height: 8),
              ]);
        });
  }

  /// Distinctive break/recess card with amber/orange theme
  Widget _breakCard(int slot) {
    final ts = _project.timeSlots[slot];
    final breakName = ts.breakName.isNotEmpty ? ts.breakName : 'Break';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCA28), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.amber.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFFA000)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('☕', style: TextStyle(fontSize: 20))),
        ),
        title: Text(breakName,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
                fontSize: 15)),
        subtitle: Text('${ts.startTime} - ${ts.endTime}',
            style: const TextStyle(fontSize: 12, color: Color(0xFFF57F17))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('RECESS',
              style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _dayCard(int slot, TimetableEntry? entry) {
    if (entry == null) {
      return Card(
          color: Colors.grey.shade50,
          child: ListTile(
            dense: true,
            leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                    child: Text('${slot + 1}',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold)))),
            title: Text(_timeLabel(slot),
                style: const TextStyle(color: AppTheme.greyText, fontSize: 13)),
            trailing: const Text('Free',
                style: TextStyle(color: AppTheme.greyText, fontSize: 12)),
          ));
    }

    final ci = _colorForSubject(entry.subjectName);
    final bg = AppTheme.subjectColors[ci % AppTheme.subjectColors.length];
    final accent = AppTheme.subjectAccents[ci % AppTheme.subjectAccents.length];

    return Card(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.cardRadius,
          side: BorderSide(
            color: entry.hasConflict ? AppTheme.error : Colors.transparent,
            width: entry.hasConflict ? 2 : 0,
          ),
        ),
        child: ListTile(
          leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Text('${slot + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
          title: Text(entry.subjectName,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: accent, fontSize: 15)),
          subtitle:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('👤 ${entry.facultyName}',
                style: const TextStyle(fontSize: 12)),
            Text('🏫 ${entry.roomId}', style: const TextStyle(fontSize: 12)),
          ]),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.hasConflict)
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.error, size: 16),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(_timeLabel(slot),
                      style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600))),
            ],
          ),
        ));
  }

  // ── Grid View with drag-drop ───────────────────────────────────────────────
  Widget _buildGridView() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _headerCell('Day/Slot', isFirst: true),
                        ...List.generate(_project.slotsPerDay, (s) {
                          if (_isBreakSlot(s)) {
                            return _breakHeaderCell(_timeLabel(s));
                          }
                          return _headerCell(_timeLabel(s));
                        })
                      ]),
                      ...List.generate(
                          _project.workingDays,
                          (day) => Row(children: [
                                _dayLabelCell(AppConst.dayLabel(day)),
                                ...List.generate(_project.slotsPerDay, (slot) {
                                  // Break slot in grid — distinct amber cell
                                  if (_isBreakSlot(slot)) {
                                    return SizedBox(
                                        width: 110,
                                        height: 80,
                                        child: _breakGridCell(slot));
                                  }
                                  final entry = _entryAt(day, slot);
                                  if (entry == null) {
                                    return SizedBox(
                                        width: 110,
                                        height: 80,
                                        child: _emptyDropCell(day, slot));
                                  }
                                  return SizedBox(
                                      width: 110,
                                      height: 80,
                                      child: _draggableCell(entry));
                                }),
                              ])),
                    ]))));
  }

  Widget _headerCell(String label, {bool isFirst = false}) => Container(
      width: isFirst ? 80 : 110,
      height: 44,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8)),
      child: Center(
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10))));

  /// Break header cell with amber gradient
  Widget _breakHeaderCell(String label) => Container(
      width: 110,
      height: 44,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFFFA000)]),
          borderRadius: BorderRadius.circular(8)),
      child: Center(
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10))));

  /// Break cell in grid view — amber with coffee icon
  Widget _breakGridCell(int slot) {
    final ts = _project.timeSlots[slot];
    final breakName = ts.breakName.isNotEmpty ? ts.breakName : 'Break';
    return Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFCA28), width: 1.5)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('☕', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(breakName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  color: Color(0xFFE65100))),
        ]));
  }

  Widget _dayLabelCell(String label) => Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Center(
          child: Text(label.substring(0, 3).toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 13))));

  Widget _draggableCell(TimetableEntry entry) {
    final ci = _colorForSubject(entry.subjectName);
    final bg = AppTheme.subjectColors[ci % AppTheme.subjectColors.length];
    final accent = AppTheme.subjectAccents[ci % AppTheme.subjectAccents.length];

    Widget content = Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: entry.hasConflict
                    ? AppTheme.error
                    : accent.withOpacity(0.4),
                width: entry.hasConflict ? 2 : 1)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
              entry.hasConflict
                  ? Icons.warning_amber_rounded
                  : Icons.drag_indicator,
              size: 10,
              color:
                  entry.hasConflict ? AppTheme.error : accent.withOpacity(0.5)),
          Text(entry.subjectName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 10, color: accent)),
          Text(entry.facultyName,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontSize: 9, color: AppTheme.greyText)),
        ]));

    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) =>
          _handleSwap(d.data.day, d.data.slot, entry.day, entry.slot),
      builder: (_, __, ___) => Draggable<_DragData>(
        data: _DragData(entry.day, entry.slot),
        feedback: Material(
            color: Colors.transparent,
            child: Opacity(
                opacity: 0.85,
                child: SizedBox(width: 106, height: 76, child: content))),
        childWhenDragging: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8))),
        child: content,
      ),
    );
  }

  Widget _emptyDropCell(int day, int slot) {
    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) =>
          _handleSwap(d.data.day, d.data.slot, day, slot),
      builder: (_, candidates, __) => Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: candidates.isNotEmpty
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)),
          child: Center(
              child: Text('—', style: TextStyle(color: Colors.grey.shade400)))),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4))
      ]),
      child: Row(children: [
        Expanded(
            child: OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WizardScreen(
                            existingProject: _currentProject,
                            user: widget.user))),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'))),
        const SizedBox(width: 12),
        Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _showExportMenu,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.ios_share),
              label: Text(_exporting ? 'Exporting…' : 'Export / Share'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            )),
      ]),
    );
  }
}

class _DragData {
  final int day;
  final int slot;
  const _DragData(this.day, this.slot);
}
