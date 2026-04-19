class ChatMessage {
  int? messageId;
  int senderId;
  int receiverId;
  String msgType; // TEXT, IMAGE
  String content;
  String? gmtCreate;

  ChatMessage({
    this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.msgType,
    required this.content,
    this.gmtCreate,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'msgType': msgType,
      'content': content,
      'gmtCreate': gmtCreate,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      msgType: json['msgType'] ?? 'TEXT',
      content: json['content'] ?? '',
      gmtCreate: json['gmtCreate'],
    );
  }
}

class Friendship {
  int? friendshipId;
  int userId;
  int friendId;
  String status; // PENDING, ACCEPTED
  String? gmtCreate;

  Friendship({
    this.friendshipId,
    required this.userId,
    required this.friendId,
    required this.status,
    this.gmtCreate,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      friendshipId: json['friendshipId'],
      userId: json['userId'],
      friendId: json['friendId'],
      status: json['status'] ?? 'PENDING',
      gmtCreate: json['gmtCreate'],
    );
  }
}
