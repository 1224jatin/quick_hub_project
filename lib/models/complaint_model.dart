import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String reporterId;
  final String? accusedId;
  final String? requestId;
  final String description;
  final DateTime timestamp;
  final String status; // 'open', 'resolved'

  ComplaintModel({
    required this.complaintId,
    required this.reporterId,
    this.accusedId,
    this.requestId,
    required this.description,
    required this.timestamp,
    this.status = 'open',
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      complaintId: json['complaintId'] as String,
      reporterId: json['reporterId'] as String,
      accusedId: json['accusedId'] as String?,
      requestId: json['requestId'] as String?,
      description: json['description'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      status: json['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaintId': complaintId,
      'reporterId': reporterId,
      'accusedId': accusedId,
      'requestId': requestId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}
