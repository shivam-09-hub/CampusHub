import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/faculty_model.dart';
import '../../models/department_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ManageFacultyScreen extends StatefulWidget {
  final UserModel user;
  const ManageFacultyScreen({super.key, required this.user});

  @override
  State<ManageFacultyScreen> createState() => _ManageFacultyScreenState();
}

class _ManageFacultyScreenState extends State<ManageFacultyScreen> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faculty')),
      body: StreamBuilder<List<FacultyModel>>(
        stream: _supabaseService.getFaculties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final faculties = snapshot.data ?? [];
          if (faculties.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.person_outline,
              title: 'No Faculty',
              subtitle: 'Add faculty members to assign them to subjects.',
              actionLabel: 'Add Faculty',
              onAction: () => _showFacultyDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faculties.length,
            itemBuilder: (_, i) {
              final f = faculties[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: AppTheme.cardRadius,
                  border: Border.all(color: AppTheme.borderColor(context)),
                  boxShadow: AppTheme.adaptiveShadow(context),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isDark
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : AppTheme.primary.withValues(alpha: 0.15),
                        child:
                            const Icon(Icons.person, color: AppTheme.primary),
                      ),
                      title: Text(f.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor(context))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.departmentName,
                              style: TextStyle(
                                  color: AppTheme.subtitleColor(context),
                                  fontSize: 13)),
                          if (f.email.isNotEmpty)
                            Text(f.email,
                                style: TextStyle(
                                    color: AppTheme.subtitleColor(context),
                                    fontSize: 12)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.edit, color: AppTheme.primary),
                            onPressed: () => _showFacultyDialog(faculty: f),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: AppTheme.error),
                            onPressed: () => _confirmDelete(f),
                          ),
                        ],
                      ),
                    ),
                    // Stats row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          _infoChip(Icons.book, '${f.subjects.length} subjects',
                              AppTheme.primary, isDark),
                          const SizedBox(width: 8),
                          _infoChip(
                              Icons.schedule,
                              'Max ${f.maxLecturesPerDay}/day',
                              AppTheme.warning,
                              isDark),
                          const SizedBox(width: 8),
                          if (f.availableDays.isNotEmpty)
                            _infoChip(
                                Icons.calendar_today,
                                '${f.availableDays.length} days',
                                AppTheme.success,
                                isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFacultyDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Faculty'),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  void _showFacultyDialog({FacultyModel? faculty}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _FacultyDialog(
          user: widget.user,
          faculty: faculty,
          supabaseService: _supabaseService),
    );
    if (result == true && mounted) {
      setState(() {});
      showAppSnackBar(context, 'Faculty saved successfully!');
    }
  }

  void _confirmDelete(FacultyModel faculty) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text('Are you sure you want to delete ${faculty.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _supabaseService.deleteFaculty(faculty.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {});
                  showAppSnackBar(context, 'Faculty deleted successfully!');
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

class _FacultyDialog extends StatefulWidget {
  final UserModel user;
  final FacultyModel? faculty;
  final SupabaseService supabaseService;

  const _FacultyDialog(
      {required this.user, this.faculty, required this.supabaseService});

  @override
  State<_FacultyDialog> createState() => _FacultyDialogState();
}

class _FacultyDialogState extends State<_FacultyDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _expertiseCtrl;
  String? _selectedDeptId;
  String? _selectedDeptName;
  List<DepartmentModel> _departments = [];
  bool _loadingDepts = true;
  bool _saving = false;
  int _maxLectures = 6;
  List<String> _subjects = [];
  List<int> _availableDays = [];
  List<int> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.faculty?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.faculty?.email ?? '');
    _expertiseCtrl = TextEditingController();
    _selectedDeptId = widget.faculty?.departmentId;
    _selectedDeptName = widget.faculty?.departmentName;
    _maxLectures = widget.faculty?.maxLecturesPerDay ?? 6;
    _subjects = List.from(widget.faculty?.subjects ?? []);
    _availableDays = List.from(widget.faculty?.availableDays ?? []);
    _availableSlots = List.from(widget.faculty?.availableSlots ?? []);
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _expertiseCtrl.dispose();
    super.dispose();
  }

  void _addExpertise() {
    final value = _expertiseCtrl.text.trim();
    if (value.isEmpty || _subjects.contains(value)) return;
    setState(() {
      _subjects.add(value);
      _expertiseCtrl.clear();
    });
  }

  Future<void> _loadDepartments() async {
    final depts = await widget.supabaseService.getDepartments().first;
    if (mounted) {
      setState(() {
        _departments = depts;
        if (_selectedDeptId == null && depts.isNotEmpty) {
          _selectedDeptId = depts.first.id;
          _selectedDeptName = depts.first.name;
        }
        _loadingDepts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDepts) {
      return const AlertDialog(
          content: SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator())));
    }

    return AlertDialog(
      title: Text(widget.faculty == null ? 'Add Faculty' : 'Edit Faculty'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Department *'),
              value: _selectedDeptId,
              items: _departments.map((d) {
                return DropdownMenuItem(value: d.id, child: Text(d.name));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDeptId = val;
                  _selectedDeptName =
                      _departments.firstWhere((d) => d.id == val).name;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Faculty Name *',
                  hintText: 'e.g. Dr. Smith',
                  prefixIcon: Icon(Icons.person),
                )),
            const SizedBox(height: 12),
            TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'e.g. smith@college.edu',
                  prefixIcon: Icon(Icons.email),
                )),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: TextField(
                  controller: _expertiseCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addExpertise(),
                  decoration: const InputDecoration(
                    labelText: 'Subject Expertise',
                    hintText: 'e.g. Data Structures',
                    prefixIcon: Icon(Icons.menu_book),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addExpertise,
                icon: const Icon(Icons.add),
                tooltip: 'Add expertise',
              ),
            ]),
            if (_subjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _subjects
                    .map((subject) => InputChip(
                          label: Text(subject),
                          onDeleted: () =>
                              setState(() => _subjects.remove(subject)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Max lectures per day
            Text('Max Lectures Per Day: $_maxLectures',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Slider(
              value: _maxLectures.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_maxLectures',
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _maxLectures = v.round()),
            ),

            // Available Days
            const Text('Available Days:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Wrap(
                spacing: 6,
                children: List.generate(
                    7,
                    (d) => FilterChip(
                          label: Text(AppConst.dayLabel(d).substring(0, 3),
                              style: const TextStyle(fontSize: 11)),
                          selected: _availableDays.contains(d),
                          onSelected: (v) => setState(() {
                            if (v) {
                              _availableDays.add(d);
                            } else {
                              _availableDays.remove(d);
                            }
                            _availableDays.sort();
                          }),
                          selectedColor:
                              AppTheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.primary,
                          visualDensity: VisualDensity.compact,
                        ))),
            const SizedBox(height: 8),
            Text('Leave empty = available all days',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.subtitleColor(context))),
            const SizedBox(height: 12),
            const Text('Available Slots:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Wrap(
                spacing: 6,
                children: List.generate(
                    10,
                    (slot) => FilterChip(
                          label: Text('S${slot + 1}',
                              style: const TextStyle(fontSize: 11)),
                          selected: _availableSlots.contains(slot),
                          onSelected: (v) => setState(() {
                            if (v) {
                              if (!_availableSlots.contains(slot)) {
                                _availableSlots.add(slot);
                              }
                            } else {
                              _availableSlots.remove(slot);
                            }
                            _availableSlots.sort();
                          }),
                          selectedColor:
                              AppTheme.success.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.success,
                          visualDensity: VisualDensity.compact,
                        ))),
            const SizedBox(height: 8),
            Text('Leave empty = available all slots',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.subtitleColor(context))),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (_nameCtrl.text.trim().isEmpty ||
                      _selectedDeptId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please fill required fields')));
                    return;
                  }
                  setState(() => _saving = true);
                  final newFac = FacultyModel(
                    id: widget.faculty?.id ??
                        'fac_${DateTime.now().millisecondsSinceEpoch}',
                    name: _nameCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    departmentId: _selectedDeptId!,
                    departmentName: _selectedDeptName!,
                    subjects: _subjects,
                    unavailableTimes: widget.faculty?.unavailableTimes ?? [],
                    maxLecturesPerDay: _maxLectures,
                    availableDays: _availableDays,
                    availableSlots: _availableSlots,
                    createdAt: widget.faculty?.createdAt ?? DateTime.now(),
                    createdBy: widget.faculty?.createdBy ?? widget.user.uid,
                  );
                  try {
                    await widget.supabaseService.saveFaculty(newFac);
                    if (mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed to save: $e'),
                            backgroundColor: AppTheme.error),
                      );
                    }
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
