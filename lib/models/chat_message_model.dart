import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String requestId;

  ChatMessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.requestId,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      requestId: json['requestId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'requestId': requestId,
    };
  }
}
