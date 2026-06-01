import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_list_controller.dart';
import '../widgets/conversation_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final chatList = Get.put(ChatListController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: const Text('ChatFlow', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white54), onPressed: () => _confirmLogout(context, auth)),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GestureDetector(
            onTap: () => Get.toNamed('/search'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15))),
              child: Row(children: [
                Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 22),
                const SizedBox(width: 12),
                Text('Search users...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
              ]),
            ),
          ),
        ),

        // Conversations list
        Expanded(
          child: Obx(() {
            if (chatList.isLoading.value && chatList.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))));
            }
            if (chatList.conversations.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text('No conversations yet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                const SizedBox(height: 8),
                Text('Tap + to start chatting', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
              ]));
            }
            return RefreshIndicator(
              color: const Color(0xFF6C63FF),
              backgroundColor: const Color(0xFF1E1E2E),
              onRefresh: () => chatList.fetchConversations(),
              child: ListView.separated(
                itemCount: chatList.conversations.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 80),
                itemBuilder: (context, index) {
                  final conv = chatList.conversations[index];
                  final otherUser = conv.getOtherUser(auth.currentUser.value?.id ?? '');
                  return ConversationTile(
                    conversation: conv,
                    currentUserId: auth.currentUser.value?.id ?? '',
                    onTap: () => Get.toNamed('/chat', arguments: {'conversationId': conv.id, 'otherUser': otherUser}),
                  );
                },
              ),
            );
          }),
        ),
      ]),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton(
          onPressed: () => Get.toNamed('/search'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () { Navigator.pop(ctx); auth.logout(); }, child: const Text('Logout', style: TextStyle(color: Color(0xFFFF6B6B)))),
        ],
      ),
    );
  }
}
