import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common_widgets.dart';

class ManageMessagesScreen extends StatefulWidget {
  final UserModel user;
  const ManageMessagesScreen({super.key, required this.user});

  @override
  State<ManageMessagesScreen> createState() => _ManageMessagesScreenState();
}

class _ManageMessagesScreenState extends State<ManageMessagesScreen> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Important Messages')),
      body: StreamBuilder<List<MessageModel>>(
        stream: _supabaseService.getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.message_outlined,
              title: 'No Messages Yet',
              subtitle: 'Send important messages to all students.',
              actionLabel: 'Send Message',
              onAction: () => _showCreateDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (_, i) => _buildMessageCard(messages[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.send),
        label: const Text('New Message'),
      ),
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    final date = DateFormat('MMM d, yyyy • h:mm a').format(message.createdAt);

    Color priorityColor;
    String priorityLabel;
    IconData priorityIcon;
    switch (message.priority) {
      case 'urgent':
        priorityColor = AppTheme.urgent;
        priorityLabel = 'URGENT';
        priorityIcon = Icons.error_rounded;
        break;
      case 'important':
        priorityColor = const Color(0xFFF59E0B);
        priorityLabel = 'IMPORTANT';
        priorityIcon = Icons.warning_rounded;
        break;
      default:
        priorityColor = AppTheme.primary;
        priorityLabel = 'NORMAL';
        priorityIcon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.adaptiveShadow(context),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(priorityIcon, color: priorityColor, size: 20),
                const SizedBox(width: 8),
                ThemedChip(text: priorityLabel, color: priorityColor),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') _confirmDelete(message);
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
            Text(message.title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppTheme.textColor(context))),
            const SizedBox(height: 6),
            Text(message.content,
                style: TextStyle(
                    color: AppTheme.subtitleColor(context),
                    fontSize: 14,
                    height: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('By ${message.createdByName}',
                    style: TextStyle(
                        color: AppTheme.subtitleColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
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
    final contentCtrl = TextEditingController();
    String priority = 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Send Message',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Holiday Announcement',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    hintText: 'Write your message here...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('🔵 Normal')),
                    DropdownMenuItem(
                        value: 'important', child: Text('🟡 Important')),
                    DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                  ],
                  onChanged: (v) => setDlg(() => priority = v!),
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
                    contentCtrl.text.trim().isEmpty) {
                  showAppSnackBar(context, 'Please fill all fields', isError: true);
                  return;
                }
                final message = MessageModel(
                  id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                  priority: priority,
                  createdBy: widget.user.uid,
                  createdByName: widget.user.name,
                  createdAt: DateTime.now(),
                );
                await _supabaseService.saveMessage(message);
                if (mounted) {
                  Navigator.pop(ctx);
                  showAppSnackBar(context, 'Message sent!');
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text('Delete "${message.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              await _supabaseService.deleteMessage(message.id);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
