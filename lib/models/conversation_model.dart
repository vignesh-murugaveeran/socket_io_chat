import 'user_model.dart';
import 'message_model.dart';

class ConversationModel {
  final String id;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final Map<String, int> unreadCount;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount = const {},
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Parse participants
    List<UserModel> participantsList = [];
    if (json['participants'] != null) {
      participantsList = (json['participants'] as List)
          .map((p) => p is Map<String, dynamic>
              ? UserModel.fromJson(p)
              : UserModel(id: p.toString(), name: '', email: ''))
          .toList();
    }

    // Parse last message
    MessageModel? lastMsg;
    if (json['lastMessage'] != null && json['lastMessage'] is Map) {
      lastMsg = MessageModel.fromJson(json['lastMessage']);
    }

    // Parse unread count
    Map<String, int> unread = {};
    if (json['unreadCount'] != null && json['unreadCount'] is Map) {
      json['unreadCount'].forEach((key, value) {
        unread[key.toString()] = (value is int) ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return ConversationModel(
      id: json['_id'] ?? json['id'] ?? '',
      participants: participantsList,
      lastMessage: lastMsg,
      unreadCount: unread,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Get the other participant in a 1-on-1 conversation
  UserModel? getOtherUser(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }
}
