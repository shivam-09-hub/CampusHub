import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../models/models.dart';
import '../../../models/user_model.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/conflict_engine.dart';
import '../../../widgets/common_widgets.dart';
import 'wizard_screen.dart';
import 'result_screen.dart';

class TimetableListScreen extends StatefulWidget {
  final UserModel user;
  const TimetableListScreen({super.key, required this.user});

  @override
  State<TimetableListScreen> createState() => _TimetableListScreenState();
}

class _TimetableListScreenState extends State<TimetableListScreen> {
  final _supabaseService = SupabaseService();
  String _sortBy = 'date'; // 'date', 'name', 'department'
  bool _sortAsc = false;
  DateTimeRange? _dateFilter;
  String? _academicYear;

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      title: 'Timetables',
      subtitle: 'Create, publish, review, and resolve timetable conflicts.',
      icon: Icons.calendar_month_rounded,
      body: StreamBuilder<List<TimetableProject>>(
        stream: _supabaseService.getTimetables(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    color: AppTheme.error, size: 48),
                const SizedBox(height: 12),
                Text('Error loading timetables:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.greyText)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          var timetables = snapshot.data ?? [];

          // Apply filters
          if (_dateFilter != null) {
            timetables = timetables
                .where((t) =>
                    t.createdAt.isAfter(
                        _dateFilter!.start.subtract(const Duration(days: 1))) &&
                    t.createdAt.isBefore(
                        _dateFilter!.end.add(const Duration(days: 1))))
                .toList();
          }
          if (_academicYear != null && _academicYear!.isNotEmpty) {
            final yearParts = _academicYear!.split('-');
            if (yearParts.length == 2) {
              final startYear = int.tryParse(yearParts[0]);
              final endYear = int.tryParse(yearParts[1]);
              if (startYear != null && endYear != null) {
                timetables = timetables
                    .where((t) =>
                        t.createdAt.year == startYear ||
                        t.createdAt.year == endYear)
                    .toList();
              }
            }
          }

          // Apply sorting
          timetables.sort((a, b) {
            int cmp;
            switch (_sortBy) {
              case 'name':
                cmp = a.className.compareTo(b.className);
                break;
              case 'department':
                cmp = a.department.compareTo(b.department);
                break;
              default:
                cmp = a.createdAt.compareTo(b.createdAt);
            }
            return _sortAsc ? cmp : -cmp;
          });

          if (timetables.isEmpty &&
              _dateFilter == null &&
              _academicYear == null) {
            return EmptyStateWidget(
              icon: Icons.calendar_today_outlined,
              title: 'No Timetables Yet',
              subtitle: 'Create your first timetable to get started.',
              actionLabel: 'Create Timetable',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        WizardScreen(existingProject: null, user: widget.user)),
              ).then((_) => setState(() {})),
            );
          }

          return Column(children: [
            _buildSortFilterBar(),
            Expanded(
              child: timetables.isEmpty
                  ? Center(
                      child: Text('No timetables match the filters',
                          style: TextStyle(
                              color: AppTheme.subtitleColor(context))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: timetables.length,
                      itemBuilder: (_, i) => _buildCard(context, timetables[i],
                          snapshot.data ?? [], _supabaseService),
                    ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  WizardScreen(existingProject: null, user: widget.user)),
        ).then((_) => setState(() {})),
        icon: const Icon(Icons.add),
        label: const Text('New Timetable'),
      ),
    );
  }

  Widget _buildSortFilterBar() {
    final isDark = AppTheme.isDark(context);
    final currentYear = DateTime.now().year;
    final academicYears = [
      '${currentYear - 1}-$currentYear',
      '$currentYear-${currentYear + 1}',
      '${currentYear + 1}-${currentYear + 2}',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D35) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF343958) : AppTheme.lightGrey,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(children: [
            // Sort dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF20243E) : const Color(0xFFF3F5FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        isDark ? const Color(0xFF343958) : AppTheme.lightGrey),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isDense: true,
                  icon: const Icon(Icons.sort, size: 16),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context)),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'department', child: Text('Dept')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v!),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Sort order toggle
            InkWell(
              onTap: () => setState(() => _sortAsc = !_sortAsc),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF20243E)
                      : const Color(0xFFF3F5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isDark ? const Color(0xFF8B84FF) : AppTheme.primary,
                ),
              ),
            ),
            const Spacer(),
            // Date range filter
            InkWell(
              onTap: () async {
                final range = await AppTheme.showAppDateRangePicker(
                  context,
                  initialDateRange: _dateFilter,
                  helpText: 'FILTER BY CREATION DATE',
                );
                if (range != null) setState(() => _dateFilter = range);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _dateFilter != null
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : (isDark
                          ? const Color(0xFF20243E)
                          : const Color(0xFFF3F5FF)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _dateFilter != null
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : (isDark
                              ? const Color(0xFF343958)
                              : AppTheme.lightGrey)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.date_range,
                      size: 14,
                      color: _dateFilter != null
                          ? AppTheme.success
                          : AppTheme.subtitleColor(context)),
                  const SizedBox(width: 4),
                  Text(
                    _dateFilter != null
                        ? '${DateFormat('MMM d').format(_dateFilter!.start)} - ${DateFormat('MMM d').format(_dateFilter!.end)}'
                        : 'Date Filter',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _dateFilter != null
                            ? AppTheme.success
                            : AppTheme.subtitleColor(context)),
                  ),
                  if (_dateFilter != null) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _dateFilter = null),
                      child: const Icon(Icons.close,
                          size: 14, color: AppTheme.error),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          // Academic year chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('All', style: TextStyle(fontSize: 11)),
                    selected: _academicYear == null,
                    onSelected: (_) => setState(() => _academicYear = null),
                    selectedColor:
                        isDark ? const Color(0xFF8B84FF) : AppTheme.primary,
                    backgroundColor:
                        isDark ? const Color(0xFF20243E) : Colors.grey.shade100,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                        color: _academicYear == null
                            ? Colors.white
                            : AppTheme.subtitleColor(context),
                        fontWeight: FontWeight.w600),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                ...academicYears.map((year) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(year, style: const TextStyle(fontSize: 11)),
                        selected: _academicYear == year,
                        onSelected: (_) => setState(() => _academicYear = year),
                        selectedColor:
                            isDark ? const Color(0xFF8B84FF) : AppTheme.primary,
                        backgroundColor: isDark
                            ? const Color(0xFF20243E)
                            : Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                            color: _academicYear == year
                                ? Colors.white
                                : AppTheme.subtitleColor(context),
                            fontWeight: FontWeight.w600),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    TimetableProject p,
    List<TimetableProject> allTimetables,
    SupabaseService fs,
  ) {
    final date = DateFormat('MMM d, yyyy').format(p.createdAt);
    final report =
        ConflictEngine.generateReport(project: p, allTimetables: allTimetables);
    final hasConflicts = report['errors'] > 0;
    final isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D35) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark ? [] : AppTheme.softShadow,
        border: isDark ? Border.all(color: const Color(0xFF343958)) : null,
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ResultScreen(project: p, messages: [], user: widget.user)),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.className,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (p.published)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Published',
                                style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (hasConflicts
                                    ? AppTheme.error
                                    : AppTheme.success)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(hasConflicts ? 'Conflict' : 'Clean',
                              style: TextStyle(
                                  color: hasConflicts
                                      ? AppTheme.error
                                      : AppTheme.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.department} • Sem ${p.semester} • ${p.workingDays} days • ${p.slotsPerDay} slots',
                      style: const TextStyle(
                          color: AppTheme.greyText, fontSize: 13),
                    ),
                    Text(date,
                        style: const TextStyle(
                            color: AppTheme.greyText, fontSize: 11)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'publish') {
                    await fs.togglePublish(p.id, !p.published);
                  } else if (v == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Timetable'),
                        content: Text('Delete "${p.className}"?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await fs.deleteTimetable(p.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(p.published ? 'Unpublish' : 'Publish'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('Delete', style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
