import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation_model.dart';

/// Conversation list tile for the home screen
/// Shows avatar, name, last message preview, time, and unread badge
class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation.getOtherUser(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final lastMessage = conversation.lastMessage;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      otherUser?.name.isNotEmpty == true
                          ? otherUser!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Online indicator dot
                if (otherUser?.isOnline == true)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0D0D1A),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser?.name ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLastMessageText(lastMessage),
                    style: TextStyle(
                      color: unreadCount > 0
                          ? Colors.white70
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Time + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation.updatedAt),
                  style: TextStyle(
                    color: unreadCount > 0
                        ? const Color(0xFF4ECDC4)
                        : Colors.white30,
                    fontSize: 12,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLastMessageText(dynamic lastMessage) {
    if (lastMessage == null) return 'Start a conversation';
    if (lastMessage.type == 'image') return '📷 Photo';
    return lastMessage.text ?? '';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}
