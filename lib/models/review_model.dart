import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String consumerId;
  final String providerId;
  final String requestId;
  final double rating;
  final String? comment;
  final DateTime timestamp;

  ReviewModel({
    required this.reviewId,
    required this.consumerId,
    required this.providerId,
    required this.requestId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] as String,
      consumerId: json['consumerId'] as String,
      providerId: json['providerId'] as String,
      requestId: json['requestId'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'consumerId': consumerId,
      'providerId': providerId,
      'requestId': requestId,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
