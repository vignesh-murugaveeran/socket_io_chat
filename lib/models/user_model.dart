class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = '',
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
