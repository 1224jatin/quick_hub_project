import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String recipientId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime timestamp;
  final Map<String, dynamic>? dataPayload; // E.g., {'requestId': '123'}

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.timestamp,
    this.dataPayload,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      recipientId: json['recipientId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      dataPayload: json['dataPayload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'dataPayload': dataPayload,
    };
  }
}
