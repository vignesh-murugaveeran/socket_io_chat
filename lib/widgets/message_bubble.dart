import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/message_model.dart';

/// Chat message bubble widget
/// - Left-aligned for received messages (grey)
/// - Right-aligned for sent messages (gradient blue)
/// - Supports text and image messages
/// - Shows timestamp and read receipts
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 12,
        right: isMe ? 12 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6C63FF),
              child: Text(
                (message.sender?.name.isNotEmpty == true)
                    ? message.sender!.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 32),

          if (!isMe) const SizedBox(width: 8),

          // Message bubble
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 81, 76, 181),
                          Color.fromARGB(255, 54, 149, 142),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : const Color(0xFF2A2D3E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: message.type == 'image'
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message content
                  if (message.type == 'image')
                    _buildImage()
                  else
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.white70,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Timestamp + read receipt
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy.length > 1
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message.readBy.length > 1
                              ? const Color(0xFF4ECDC4)
                              : Colors.white54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = message.imageUrl.startsWith('http')
        ? message.imageUrl
        : '${AppConfig.baseUrl}${message.imageUrl}';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          maxHeightDiskCache: 300,
          placeholder: (context, url) => Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
            ),
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd/MM HH:mm').format(dateTime);
    }
  }
}
