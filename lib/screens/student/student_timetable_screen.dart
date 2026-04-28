import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class StudentTimetableScreen extends StatelessWidget {
  final UserModel user;
  const StudentTimetableScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Timetable')),
      body: StreamBuilder<List<TimetableProject>>(
        stream: SupabaseService().getPublishedTimetables(department: user.department, semester: user.semester),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final timetables = snapshot.data ?? [];
          if (timetables.isEmpty) return const EmptyStateWidget(icon: Icons.calendar_today_outlined, title: 'No Timetable Yet', subtitle: 'Your admin hasn\'t published a timetable for your class yet.');

          return DefaultTabController(length: timetables.length, child: Column(children: [
            if (timetables.length > 1) TabBar(isScrollable: true, tabs: timetables.map((t) => Tab(text: t.className)).toList()),
            Expanded(child: TabBarView(children: timetables.map((t) => _TimetableView(project: t)).toList())),
          ]));
        },
      ),
    );
  }
}

class _TimetableView extends StatelessWidget {
  final TimetableProject project;
  const _TimetableView({required this.project});

  String _timeLabel(int slot) {
    if (slot < project.timeSlots.length) {
      final ts = project.timeSlots[slot];
      if (ts.isBreak) return ts.breakName.isNotEmpty ? ts.breakName : 'Break';
      return '${ts.startTime} - ${ts.endTime}';
    }
    return 'Slot ${slot + 1}';
  }

  bool _isBreakSlot(int slot) {
    return slot < project.timeSlots.length && project.timeSlots[slot].isBreak;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: project.workingDays, itemBuilder: (_, day) {
      final dayEntries = project.entries.where((e) => e.day == day).toList()..sort((a, b) => a.slot.compareTo(b.slot));
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)), child: Text(AppConst.dayLabel(day), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(width: 8),
          Text('${dayEntries.where((e) => !_isBreakSlot(e.slot)).length} classes',
              style: TextStyle(color: AppTheme.subtitleColor(context), fontSize: 13)),
        ])),
        ...List.generate(project.slotsPerDay, (slot) {
          // ── Break/Recess slot — distinct amber card ──
          if (_isBreakSlot(slot)) {
            final ts = project.timeSlots[slot];
            final breakName = ts.breakName.isNotEmpty ? ts.breakName : 'Break';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF3D2E00), Color(0xFF4A3800)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : const LinearGradient(
                        colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCA28), width: 1.5),
                boxShadow: isDark ? [] : [BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFFA000)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('☕', style: TextStyle(fontSize: 20))),
                ),
                title: Text(breakName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
                        fontSize: 15)),
                subtitle: Text('${ts.startTime} - ${ts.endTime}',
                    style: TextStyle(fontSize: 12,
                        color: isDark ? const Color(0xFFFFE082) : const Color(0xFFF57F17))),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('RECESS', style: TextStyle(
                    color: isDark ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
                    fontSize: 10, fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
                ),
              ),
            );
          }

          // ── Free slot ──
          final entry = dayEntries.where((e) => e.slot == slot).firstOrNull;
          if (entry == null) {
            return Card(
              color: isDark ? const Color(0xFF1E1E36) : Colors.grey.shade50,
              child: ListTile(
                dense: true,
                leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${slot + 1}',
                      style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontWeight: FontWeight.bold)))),
                title: Text(_timeLabel(slot),
                    style: TextStyle(color: AppTheme.subtitleColor(context), fontSize: 13)),
                trailing: Text('Free',
                    style: TextStyle(color: AppTheme.subtitleColor(context), fontSize: 12)),
              ),
            );
          }

          // ── Subject slot ──
          final ci = project.subjects.firstWhere((s) => s.name == entry.subjectName, orElse: () => SubjectModel(id: '', name: '', facultyName: '', hoursPerWeek: 0)).colorIndex;
          final bg = isDark
              ? AppTheme.subjectAccents[ci % AppTheme.subjectAccents.length].withValues(alpha: 0.15)
              : AppTheme.subjectColors[ci % AppTheme.subjectColors.length];
          final accent = AppTheme.subjectAccents[ci % AppTheme.subjectAccents.length];

          return Card(color: bg, child: ListTile(
            leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('${slot + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            title: Text(entry.subjectName, style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
            subtitle: Text('👤 ${entry.facultyName} • 🏫 ${entry.roomId}',
                style: TextStyle(fontSize: 12, color: AppTheme.subtitleColor(context))),
            trailing: Text(_timeLabel(slot), style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600)),
          ));
        }),
        const SizedBox(height: 8),
      ]);
    });
  }
}

