import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/conversation_model.dart';

import '../services/api_service.dart';
import '../services/socket_service.dart';


/// Manages the list of conversations on the home screen
/// Listens for realtime message updates to refresh the list
class ChatListController extends GetxController {
  static ChatListController get to => Get.find<ChatListController>();

  final conversations = <ConversationModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
    _setupSocketListeners();
  }

  /// Fetch all conversations from the API
  Future<void> fetchConversations() async {
    isLoading.value = true;
    try {
      final response = await ApiService.to.get('/conversations');
      final data = response.data;

      if (data['success'] == true) {
        final list = (data['data']['conversations'] as List)
            .map((c) => ConversationModel.fromJson(c))
            .toList();
        conversations.value = list;
      }
    } catch (e) {
      debugPrint('Fetch conversations error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Setup socket listeners for realtime updates
  void _setupSocketListeners() {
    // Listen for new message notifications to update conversation list
    SocketService.to.on('new_message_notification', (data) {
      _handleNewMessage(data);
    });

    // Listen for user status changes
    SocketService.to.on('user_status', (data) {
      _handleUserStatus(data);
    });
  }

  void _handleNewMessage(dynamic data) {
    if (data == null) return;

    final conversationId = data['conversationId'] as String?;
    if (conversationId == null) return;

    // Refresh conversations to get updated last message and unread counts
    fetchConversations();
  }

  void _handleUserStatus(dynamic data) {
    if (data == null) return;

    final userId = data['userId'] as String?;
    final _ = data['isOnline'] as bool? ?? false;

    if (userId == null) return;

    // Update online status in the conversation list
    for (int i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      for (int j = 0; j < conv.participants.length; j++) {
        if (conv.participants[j].id == userId) {
          // Force refresh to update UI
          conversations.refresh();
          return;
        }
      }
    }
  }

  /// Create or get existing conversation with a user
  Future<ConversationModel?> getOrCreateConversation(
      String participantId) async {
    try {
      final response = await ApiService.to.post('/conversations', data: {
        'participantId': participantId,
      });

      final data = response.data;
      if (data['success'] == true) {
        final conversation =
            ConversationModel.fromJson(data['data']['conversation']);

        // Refresh the list
        await fetchConversations();
        return conversation;
      }
    } catch (e) {
      debugPrint('Create conversation error: $e');
    }
    return null;
  }

  @override
  void onClose() {
    SocketService.to.off('new_message_notification');
    SocketService.to.off('user_status');
    super.onClose();
  }
}
