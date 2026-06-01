import 'user_model.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final UserModel? sender;
  final String senderId;
  final String text;
  final String imageUrl;
  final String type; // 'text' or 'image'
  final List<String> readBy;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    this.sender,
    this.senderId = '',
    this.text = '',
    this.imageUrl = '',
    this.type = 'text',
    this.readBy = const [],
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // sender can be a populated object or just a string ID
    UserModel? senderModel;
    String sId = '';

    if (json['sender'] is Map<String, dynamic>) {
      senderModel = UserModel.fromJson(json['sender']);
      sId = senderModel.id;
    } else if (json['sender'] is String) {
      sId = json['sender'];
    }

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      sender: senderModel,
      senderId: sId,
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? 'text',
      readBy: json['readBy'] != null
          ? List<String>.from(json['readBy'].map((e) => e.toString()))
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'conversationId': conversationId,
      'sender': sender?.toJson() ?? senderId,
      'text': text,
      'imageUrl': imageUrl,
      'type': type,
      'readBy': readBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
