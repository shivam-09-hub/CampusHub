import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/department_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class ManageDepartmentsScreen extends StatefulWidget {
  final UserModel user;
  const ManageDepartmentsScreen({super.key, required this.user});

  @override
  State<ManageDepartmentsScreen> createState() =>
      _ManageDepartmentsScreenState();
}

class _ManageDepartmentsScreenState extends State<ManageDepartmentsScreen> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      title: 'Manage Departments',
      subtitle: 'Organize programs used by classes, faculty, and students.',
      icon: Icons.domain_rounded,
      body: StreamBuilder<List<DepartmentModel>>(
        stream: _supabaseService.getDepartments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final depts = snapshot.data ?? [];
          if (depts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.domain,
              title: 'No Departments',
              subtitle:
                  'Add departments to start managing classes and faculty.',
              actionLabel: 'Add Department',
              onAction: () => _showDeptDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: depts.length,
            itemBuilder: (_, i) {
              final d = depts[i];
              return ThemedListCard(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(
                          alpha: AppTheme.isDark(context) ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.domain,
                        color: AppTheme.primary, size: 22),
                  ),
                  title: Text(d.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor(context))),
                  subtitle: Text(
                      'Created: ${DateFormat.yMMMd().format(d.createdAt)}',
                      style: TextStyle(color: AppTheme.subtitleColor(context))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppTheme.primary),
                        onPressed: () => _showDeptDialog(dept: d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.error),
                        onPressed: () => _confirmDelete(d),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeptDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Dept'),
      ),
    );
  }

  void _showDeptDialog({DepartmentModel? dept}) {
    final nameCtrl = TextEditingController(text: dept?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dept == null ? 'Add Department' : 'Edit Department'),
        content: SingleChildScrollView(
          child: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Department Name', hintText: 'e.g. Computer Science'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final newDept = DepartmentModel(
                id: dept?.id ?? 'dept_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                createdAt: dept?.createdAt ?? DateTime.now(),
                createdBy: dept?.createdBy ?? widget.user.uid,
              );
              try {
                await _supabaseService.saveDepartment(newDept);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {}); // trigger StreamBuilder rebuild
                  showAppSnackBar(context, 'Department saved successfully!');
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  showAppSnackBar(context, 'Failed to save: $e', isError: true);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DepartmentModel dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
            'Are you sure you want to delete ${dept.name}? Make sure no classes are using it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _supabaseService.deleteDepartment(dept.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {}); // trigger StreamBuilder rebuild
                  showAppSnackBar(context, 'Department deleted successfully!');
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  showAppSnackBar(context, 'Failed to delete: $e',
                      isError: true);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
