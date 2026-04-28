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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetables')),
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
          final timetables = snapshot.data ?? [];

          if (timetables.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: timetables.length,
            itemBuilder: (_, i) => _buildCard(
                context, timetables[i], timetables, _supabaseService),
          );
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
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
                              color: AppTheme.success.withOpacity(0.1),
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
                                .withOpacity(0.1),
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
