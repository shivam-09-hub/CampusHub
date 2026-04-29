import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import 'manage_students_screen.dart';
import 'manage_notices_screen.dart';
import 'manage_notes_screen.dart';
import 'manage_messages_screen.dart';
import 'timetable/wizard_screen.dart';
import 'timetable/timetable_list_screen.dart';
import 'manage_departments_screen.dart';
import 'manage_classes_screen.dart';
import 'manage_faculty_screen.dart';
import 'manage_rooms_screen.dart';
import 'manage_subjects_screen.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  final _supabaseService = SupabaseService();

  int _studentCount = 0;
  int _timetableCount = 0;
  int _noticeCount = 0;
  int _messageCount = 0;
  int _departmentCount = 0;
  int _classCount = 0;
  int _facultyCount = 0;
  int _subjectCount = 0;
  int _roomCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final students = await _supabaseService.getUserCount('student');
      final timetables = await _supabaseService.getTimetableCount();
      final notices = await _supabaseService.getNoticeCount();
      final messages = await _supabaseService.getMessageCount();
      final departments = await _supabaseService.getDepartmentCount();
      final classes = await _supabaseService.getClassCount();
      final faculty = await _supabaseService.getFacultyCount();
      final subjects = await _supabaseService.getSubjectCount();
      final rooms = await _supabaseService.getRoomCount();
      if (mounted) {
        setState(() {
          _studentCount = students;
          _timetableCount = timetables;
          _noticeCount = notices;
          _messageCount = messages;
          _departmentCount = departments;
          _classCount = classes;
          _facultyCount = faculty;
          _subjectCount = subjects;
          _roomCount = rooms;
        });
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _cycleTheme() async {
    final ts = ThemeService();
    if (ts.themeMode == ThemeMode.light) {
      await ts.setThemeMode(ThemeMode.dark);
    } else if (ts.themeMode == ThemeMode.dark) {
      await ts.setThemeMode(ThemeMode.system);
    } else {
      await ts.setThemeMode(ThemeMode.light);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.screenGradient(context)),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStats,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // ── Quick Stats ───────────────────────────────────────────
                  const SectionTitle(title: 'Overview'),
                  _buildStatsRow(),
                  const SizedBox(height: 28),

                  // ── Features ──────────────────────────────────────────────
                  const SectionTitle(title: 'Manage'),
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = AppTheme.isDark(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.20),
            ),
            boxShadow:
                AppTheme.glowShadow(AppTheme.primary, intensity: 0.25),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${widget.user.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Text(
                        '✦ Admin / Faculty',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              _headerButton(
                onTap: _cycleTheme,
                child: AnimatedBuilder(
                    animation: ThemeService(),
                    builder: (context, _) {
                      IconData icon = Icons.brightness_auto;
                      if (ThemeService().themeMode == ThemeMode.light) {
                        icon = Icons.light_mode;
                      }
                      if (ThemeService().themeMode == ThemeMode.dark) {
                        icon = Icons.dark_mode;
                      }
                      return Icon(icon, color: Colors.white, size: 22);
                    }),
              ),
              const SizedBox(width: 10),
              _headerButton(
                onTap: _logout,
                child: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: (constraints.maxWidth - 10) / 2,
                child: StatCard(
                  label: 'Students',
                  value: '$_studentCount',
                  icon: Icons.people_outline,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - 10) / 2,
                child: StatCard(
                  label: 'Timetables',
                  value: '$_timetableCount',
                  icon: Icons.calendar_today_outlined,
                  color: AppTheme.success,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - 10) / 2,
                child: StatCard(
                  label: 'Notices',
                  value: '$_noticeCount',
                  icon: Icons.campaign_outlined,
                  color: AppTheme.warning,
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Students',
                value: '$_studentCount',
                icon: Icons.people_outline,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Timetables',
                value: '$_timetableCount',
                icon: Icons.calendar_today_outlined,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Notices',
                value: '$_noticeCount',
                icon: Icons.campaign_outlined,
                color: AppTheme.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(
        'Timetable',
        'Create & manage schedules',
        Icons.calendar_month_rounded,
        AppTheme.primary,
        '$_timetableCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TimetableListScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Students',
        'Create & manage accounts',
        Icons.people_rounded,
        const Color(0xFF8B5CF6),
        '$_studentCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ManageStudentsScreen(adminUser: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Notices',
        'Post announcements',
        Icons.campaign_rounded,
        AppTheme.accent,
        '$_noticeCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageNoticesScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Notes',
        'Upload study materials',
        Icons.note_alt_rounded,
        AppTheme.success,
        null,
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageNotesScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Messages',
        'Send important updates',
        Icons.message_rounded,
        AppTheme.rose,
        '$_messageCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageMessagesScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Departments',
        'Manage departments',
        Icons.domain_rounded,
        const Color(0xFF5B6CF7),
        '$_departmentCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageDepartmentsScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Classes',
        'Manage semesters & sections',
        Icons.class_rounded,
        AppTheme.secondary,
        '$_classCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageClassesScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Faculty',
        'Manage teachers',
        Icons.person_rounded,
        const Color(0xFF6366F1),
        '$_facultyCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageFacultyScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Subjects',
        'Manage curriculum',
        Icons.menu_book_rounded,
        const Color(0xFFE76F51),
        '$_subjectCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageSubjectsScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'Classrooms',
        'Manage rooms & capacity',
        Icons.meeting_room_rounded,
        const Color(0xFF8D6E63),
        '$_roomCount',
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageRoomsScreen(user: widget.user)))
            .then((_) => _loadStats()),
      ),
      _FeatureItem(
        'New Timetable',
        'Create from scratch',
        Icons.add_circle_rounded,
        AppTheme.secondary,
        null,
        () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        WizardScreen(existingProject: null, user: widget.user)))
            .then((_) => _loadStats()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 300 ? 1 : 2;
        final aspectRatio = constraints.maxWidth < 300 ? 2.0 : 1.1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: features.length,
          itemBuilder: (_, i) {
            final f = features[i];
            return DashboardCard(
              title: f.title,
              subtitle: f.subtitle,
              icon: f.icon,
              color: f.color,
              badge: f.badge,
              onTap: f.onTap,
            );
          },
        );
      },
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  _FeatureItem(
      this.title, this.subtitle, this.icon, this.color, this.badge, this.onTap);
}
