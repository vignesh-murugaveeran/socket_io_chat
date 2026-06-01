import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'auth_controller.dart';

/// Manages individual chat screen state
/// - Lazy loading with pagination (20 messages per page)
/// - Realtime message receiving via socket
/// - Typing indicators
/// - Image sending
class ChatController extends GetxController {
  final String conversationId;
  final UserModel otherUser;

  ChatController({
    required this.conversationId,
    required this.otherUser,
  });

  // Messages
  final messages = <MessageModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _currentPage = 1;

  // Typing
  final isOtherTyping = false.obs;
  Timer? _typingTimer;

  // Input
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  // Sending state
  final isSending = false.obs;

  String get _currentUserId => AuthController.to.currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();

    // Join the conversation room
    SocketService.to.emit('join_conversation', {
      'conversationId': conversationId,
    });

    // Mark messages as read
    SocketService.to.emit('mark_read', {
      'conversationId': conversationId,
    });

    // Load initial messages
    _loadMessages();

    // Setup socket listeners
    _setupSocketListeners();

    // Setup scroll listener for lazy loading
    scrollController.addListener(_onScroll);
  }

  // ─── Message Loading (Pagination) ─────────────────────────────────────────

  /// Load messages for current page
  Future<void> _loadMessages() async {
    isLoading.value = true;
    try {
      final response = await ApiService.to.get(
        '/messages/$conversationId',
        queryParameters: {
          'page': _currentPage,
          'limit': AppConfig.messagesPerPage,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        final newMessages = (data['data']['messages'] as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();

        final pagination = data['data']['pagination'];
        hasMore.value = pagination['hasMore'] ?? false;

        if (_currentPage == 1) {
          messages.value = newMessages;
        } else {
          // Prepend older messages at the beginning
          messages.insertAll(0, newMessages);
        }
      }
    } catch (e) {
      debugPrint('Load messages error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more messages when scroll reaches the top (reverse ListView)
  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    _currentPage++;

    try {
      final response = await ApiService.to.get(
        '/messages/$conversationId',
        queryParameters: {
          'page': _currentPage,
          'limit': AppConfig.messagesPerPage,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        final newMessages = (data['data']['messages'] as List)
            .map((m) => MessageModel.fromJson(m))
            .toList();

        final pagination = data['data']['pagination'];
        hasMore.value = pagination['hasMore'] ?? false;

        // Prepend older messages
        messages.insertAll(0, newMessages);
      }
    } catch (e) {
      debugPrint('Load more messages error: $e');
      _currentPage--; // Revert page on error
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Scroll listener — triggers lazy load when user scrolls to top
  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100) {
      // In a reverse ListView, maxScrollExtent is at the top (oldest messages)
      loadMoreMessages();
    }
  }

  // ─── Socket Listeners ─────────────────────────────────────────────────────

  void _setupSocketListeners() {
    // Receive new messages
    SocketService.to.on('receive_message', (data) {
      if (data == null) return;

      final msgData = data['message'];
      final convId = data['conversationId'];

      if (convId == conversationId && msgData != null) {
        final message = MessageModel.fromJson(msgData);

        // Avoid duplicates
        if (!messages.any((m) => m.id == message.id)) {
          messages.add(message);

          // Auto-scroll to bottom for new messages
          _scrollToBottom();

          // Mark as read
          SocketService.to.emit('mark_read', {
            'conversationId': conversationId,
          });
        }
      }
    });

    // Typing indicators
    SocketService.to.on('typing', (data) {
      if (data != null &&
          data['conversationId'] == conversationId &&
          data['userId'] != _currentUserId) {
        isOtherTyping.value = true;
      }
    });

    SocketService.to.on('stop_typing', (data) {
      if (data != null &&
          data['conversationId'] == conversationId &&
          data['userId'] != _currentUserId) {
        isOtherTyping.value = false;
      }
    });

    // Read receipts
    SocketService.to.on('message_read', (data) {
      if (data != null && data['conversationId'] == conversationId) {
        // Refresh messages to update read status
        messages.refresh();
      }
    });
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  /// Send a text message via socket
  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    SocketService.to.emit('send_message', {
      'conversationId': conversationId,
      'text': text,
      'type': 'text',
    });

    // Clear input and stop typing
    messageController.clear();
    _emitStopTyping();
  }

  /// Send an image message
  Future<void> sendImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      isSending.value = true;

      // Upload image via REST API
      final response = await ApiService.to.uploadImage(
        '/messages/upload',
        filePath: image.path,
        fieldName: 'image',
        extraFields: {'conversationId': conversationId},
      );

      if (response.data['success'] == true) {
        // The server will broadcast via socket, so message appears automatically
        debugPrint('Image sent successfully');
      }
    } catch (e) {
      debugPrint('Send image error: $e');
      Get.snackbar('Error', 'Failed to send image',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }

  // ─── Typing Indicators ────────────────────────────────────────────────────

  /// Emit typing event with debounce
  void onTyping() {
    SocketService.to.emit('typing', {
      'conversationId': conversationId,
    });

    // Auto stop typing after 2 seconds of no input
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _emitStopTyping);
  }

  void _emitStopTyping() {
    SocketService.to.emit('stop_typing', {
      'conversationId': conversationId,
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollController.animateTo(
          0, // In reverse ListView, 0 is the bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Check if a message was sent by the current user
  bool isMyMessage(MessageModel message) {
    return message.senderId == _currentUserId ||
        message.sender?.id == _currentUserId;
  }

  @override
  void onClose() {
    // Leave room
    SocketService.to.emit('leave_conversation', {
      'conversationId': conversationId,
    });

    // Remove listeners for this conversation
    SocketService.to.off('receive_message');
    SocketService.to.off('typing');
    SocketService.to.off('stop_typing');
    SocketService.to.off('message_read');

    // Dispose controllers
    messageController.dispose();
    scrollController.dispose();
    _typingTimer?.cancel();

    super.onClose();
  }
}
