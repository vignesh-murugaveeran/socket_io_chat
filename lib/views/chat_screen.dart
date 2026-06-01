import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../models/user_model.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final conversationId = args['conversationId'] as String;
    final otherUser = args['otherUser'] as UserModel?;

    final controller = Get.put(
      ChatController(
        conversationId: conversationId,
        otherUser: otherUser ?? UserModel(id: '', name: 'Unknown', email: ''),
      ),
      tag: conversationId,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  otherUser?.name.isNotEmpty == true
                      ? otherUser!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser?.name ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(
                    () => Text(
                      controller.isOtherTyping.value
                          ? 'typing...'
                          : (otherUser?.isOnline == true
                                ? 'Online'
                                : 'Offline'),
                      style: TextStyle(
                        color: controller.isOtherTyping.value
                            ? const Color(0xFF4ECDC4)
                            : (otherUser?.isOnline == true
                                  ? const Color(0xFF4ECDC4)
                                  : Colors.white38),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C63FF),
                    ),
                  ),
                );
              }
              if (controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.waving_hand,
                        size: 60,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Say hello! 👋',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  // Loading more indicator
                  Obx(
                    () => controller.isLoadingMore.value
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller.scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        // Reverse index for reverse ListView
                        final msgIndex = controller.messages.length - 1 - index;
                        final message = controller.messages[msgIndex];
                        final isMe = controller.isMyMessage(message);
                        return MessageBubble(message: message, isMe: isMe);
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
          // Typing indicator
          Obx(
            () => controller.isOtherTyping.value
                ? const TypingIndicator()
                : const SizedBox.shrink(),
          ),
          // Input bar
          Obx(
            () => ChatInputBar(
              controller: controller.messageController,
              onSend: controller.sendMessage,
              onTyping: (_) => controller.onTyping(),
              onPickImage: (source) => controller.sendImage(source: source),
              isSending: controller.isSending.value,
            ),
          ),
        ],
      ),
    );
  }
}
