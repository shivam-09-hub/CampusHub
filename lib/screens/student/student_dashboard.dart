import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../../services/theme_service.dart';
import '../auth/login_screen.dart';
import 'student_timetable_screen.dart';
import 'student_notices_screen.dart';
import 'student_notes_screen.dart';
import 'student_messages_screen.dart';

class StudentDashboard extends StatelessWidget {
  final UserModel user;
  const StudentDashboard({super.key, required this.user});

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Quick Access'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 300 ? 1 : 2;
                  final aspectRatio = constraints.maxWidth < 300 ? 2.0 : 1.1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                    children: [
                      DashboardCard(
                        title: 'My Timetable',
                        subtitle: 'View your schedule',
                        icon: Icons.calendar_month_rounded,
                        color: AppTheme.primary,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    StudentTimetableScreen(user: user))),
                      ),
                      DashboardCard(
                        title: 'Notices',
                        subtitle: 'Announcements',
                        icon: Icons.campaign_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    StudentNoticesScreen(user: user))),
                      ),
                      DashboardCard(
                        title: 'Notes',
                        subtitle: 'Study materials',
                        icon: Icons.note_alt_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    StudentNotesScreen(user: user))),
                      ),
                      DashboardCard(
                        title: 'Messages',
                        subtitle: 'Important updates',
                        icon: Icons.message_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const StudentMessagesScreen())),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user.name} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🎓 ${user.department} • Sem ${user.semester}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _cycleTheme,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
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
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
