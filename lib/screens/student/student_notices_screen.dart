import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/notice_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class StudentNoticesScreen extends StatelessWidget {
  final UserModel user;
  const StudentNoticesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CampusScaffold(
      title: 'Notices',
      subtitle: 'Latest announcements for your department and semester.',
      icon: Icons.campaign_rounded,
      body: StreamBuilder<List<NoticeModel>>(
        stream: SupabaseService().getNoticesForStudent(
            department: user.department, semester: user.semester),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: 'No Notices',
              subtitle: 'No announcements for you right now.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (_, i) {
              final n = notices[i];
              final date =
                  DateFormat('MMM d, yyyy • h:mm a').format(n.createdAt);
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
                            child: Text(n.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.textColor(context))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(n.description,
                          style: TextStyle(
                              color: AppTheme.subtitleColor(context),
                              fontSize: 14,
                              height: 1.5)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('By ${n.createdByName}',
                              style: TextStyle(
                                  color: AppTheme.subtitleColor(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(date,
                              style: TextStyle(
                                  color: AppTheme.subtitleColor(context),
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
