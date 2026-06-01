import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_list_controller.dart';
import '../controllers/user_search_controller.dart';
import '../models/user_model.dart';

class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserSearchController());
    final auth = AuthController.to;

    // Load all users initially
    controller.fetchAllUsers();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text('New Chat', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // User list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                  ),
                );
              }

              if (controller.users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search, size: 60, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text(
                        controller.hasSearched.value ? 'No users found' : 'No users available',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.users.length,
                itemBuilder: (context, index) {
                  final user = controller.users[index];
                  return _buildUserTile(user, auth);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user, AuthController auth) {
    return InkWell(
      onTap: () => _startConversation(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                ],
              ),
            ),
            // Online indicator
            if (user.isOnline)
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: Color(0xFF4ECDC4), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startConversation(UserModel user) async {
    final chatList = Get.find<ChatListController>();
    final conversation = await chatList.getOrCreateConversation(user.id);
    if (conversation != null) {
      Get.offNamed('/chat', arguments: {
        'conversationId': conversation.id,
        'otherUser': user,
      });
    }
  }
}
