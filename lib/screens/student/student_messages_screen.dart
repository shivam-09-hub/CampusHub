import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/message_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class StudentMessagesScreen extends StatelessWidget {
  const StudentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<MessageModel>>(
        stream: SupabaseService().getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final messages = snapshot.data ?? [];
          if (messages.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.message_outlined,
              title: 'No Messages',
              subtitle: 'No important messages right now.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final m = messages[i];
              final date = DateFormat('MMM d, yyyy • h:mm a').format(m.createdAt);
              Color pc;
              String pl;
              IconData pi;
              switch (m.priority) {
                case 'urgent':
                  pc = AppTheme.urgent;
                  pl = 'URGENT';
                  pi = Icons.error_rounded;
                  break;
                case 'important':
                  pc = const Color(0xFFF59E0B);
                  pl = 'IMPORTANT';
                  pi = Icons.warning_rounded;
                  break;
                default:
                  pc = AppTheme.primary;
                  pl = 'INFO';
                  pi = Icons.info_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.adaptiveShadow(context),
                  border: Border(left: BorderSide(color: pc, width: 4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(pi, color: pc, size: 20),
                          const SizedBox(width: 8),
                          ThemedChip(text: pl, color: pc),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(m.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppTheme.textColor(context))),
                      const SizedBox(height: 6),
                      Text(m.content,
                          style: TextStyle(
                              color: AppTheme.subtitleColor(context),
                              fontSize: 14,
                              height: 1.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('By ${m.createdByName}',
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
