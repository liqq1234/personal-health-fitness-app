class Friendship {
  final int userId;
  final int friendId;
  final String status;
  final String gmtCreate;

  Friendship({
    required this.userId,
    required this.friendId,
    required this.status,
    required this.gmtCreate,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      userId: json['userId'],
      friendId: json['friendId'],
      status: json['status'],
      gmtCreate: json['gmtCreate'],
    );
  }
}

class SocialMoment {
  final int? momentId;
  final int userId;
  final String content;
  final String? images;
  final String gmtCreate;

  SocialMoment({
    this.momentId,
    required this.userId,
    required this.content,
    this.images,
    required this.gmtCreate,
  });

  factory SocialMoment.fromJson(Map<String, dynamic> json) {
    return SocialMoment(
      momentId: json['momentId'],
      userId: json['userId'],
      content: json['content'],
      images: json['images'],
      gmtCreate: json['gmtCreate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'momentId': momentId,
      'userId': userId,
      'content': content,
      'images': images,
      'gmtCreate': gmtCreate,
    };
  }
}

class ChatMessage {
  final int? messageId;
  final int senderId;
  final int receiverId;
  final String content;
  final String? messageType;
  final String gmtCreate;

  ChatMessage({
    this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = 'TEXT',
    required this.gmtCreate,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      messageType: json['messageType'],
      gmtCreate: json['gmtCreate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType,
      'gmtCreate': gmtCreate,
    };
  }
}

class SocialComment {
  final int? commentId;
  final int momentId;
  final int userId;
  final String content;
  final String gmtCreate;

  SocialComment({
    this.commentId,
    required this.momentId,
    required this.userId,
    required this.content,
    required this.gmtCreate,
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      commentId: json['commentId'],
      momentId: json['momentId'],
      userId: json['userId'],
      content: json['content'],
      gmtCreate: json['gmtCreate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'momentId': momentId,
      'userId': userId,
      'content': content,
      'gmtCreate': gmtCreate,
    };
  }
}
