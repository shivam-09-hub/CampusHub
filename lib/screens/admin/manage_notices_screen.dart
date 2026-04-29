import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/notice_model.dart';
import '../../models/department_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ManageNoticesScreen extends StatefulWidget {
  final UserModel user;
  const ManageNoticesScreen({super.key, required this.user});

  @override
  State<ManageNoticesScreen> createState() => _ManageNoticesScreenState();
}

class _ManageNoticesScreenState extends State<ManageNoticesScreen> {
  final _supabaseService = SupabaseService();
  List<DepartmentModel> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final depts = await _supabaseService.getDepartments().first;
      if (mounted) setState(() => _departments = depts);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      title: 'Manage Notices',
      subtitle: 'Publish announcements to all students or departments.',
      icon: Icons.campaign_rounded,
      body: StreamBuilder<List<NoticeModel>>(
        stream: _supabaseService.getNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'No Notices Yet',
              subtitle: 'Create a notice to share announcements with students.',
              actionLabel: 'Create Notice',
              onAction: () => _showCreateDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (_, i) => _buildNoticeCard(notices[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Notice'),
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    final date = DateFormat('MMM d, yyyy • h:mm a').format(notice.createdAt);
    return ThemedListCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(
                        alpha: AppTheme.isDark(context) ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.campaign_rounded,
                      color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(notice.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textColor(context))),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') _confirmDelete(notice);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppTheme.error))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(notice.description,
                style: TextStyle(
                    color: AppTheme.subtitleColor(context),
                    fontSize: 14,
                    height: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                ThemedChip(
                  text:
                      'To: ${notice.targetAudience == 'all' ? 'All Students' : notice.targetAudience}',
                  color: AppTheme.primary,
                ),
                const Spacer(),
                Text(date,
                    style: TextStyle(
                        color: AppTheme.subtitleColor(context), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String audience = 'all';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Create Notice',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Exam Schedule Released',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Write the notice content here...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('All Students')),
                    ..._departments.map((d) =>
                        DropdownMenuItem(value: d.name, child: Text(d.name))),
                  ],
                  onChanged: (v) => setDlg(() => audience = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    descCtrl.text.trim().isEmpty) {
                  showAppSnackBar(context, 'Please fill all fields',
                      isError: true);
                  return;
                }
                final notice = NoticeModel(
                  id: 'notice_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  targetAudience: audience,
                  createdBy: widget.user.uid,
                  createdByName: widget.user.name,
                  createdAt: DateTime.now(),
                );
                await _supabaseService.saveNotice(notice);
                if (mounted) {
                  Navigator.pop(ctx);
                  showAppSnackBar(context, 'Notice published!');
                }
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice'),
        content: Text('Delete "${notice.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await _supabaseService.deleteNotice(notice.id);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
