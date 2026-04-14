import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, completed, failed, refunded }

class TransactionModel {
  final String transactionId;
  final String requestId;
  final String consumerId;
  final String providerId;
  final double totalAmount;
  final double commissionAmount; // Amount platform takes
  final double providerEarnings; // Amount provider gets
  final DateTime timestamp;
  final PaymentStatus status;
  final String paymentMethod;

  TransactionModel({
    required this.transactionId,
    required this.requestId,
    required this.consumerId,
    required this.providerId,
    required this.totalAmount,
    required this.commissionAmount,
    required this.providerEarnings,
    required this.timestamp,
    required this.status,
    required this.paymentMethod,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    PaymentStatus parsedStatus;
    switch (json['status']) {
      case 'completed': parsedStatus = PaymentStatus.completed; break;
      case 'failed': parsedStatus = PaymentStatus.failed; break;
      case 'refunded': parsedStatus = PaymentStatus.refunded; break;
      default: parsedStatus = PaymentStatus.pending;
    }

    return TransactionModel(
      transactionId: json['transactionId'] as String,
      requestId: json['requestId'] as String,
      consumerId: json['consumerId'] as String,
      providerId: json['providerId'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      commissionAmount: (json['commissionAmount'] as num).toDouble(),
      providerEarnings: (json['providerEarnings'] as num).toDouble(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      status: parsedStatus,
      paymentMethod: json['paymentMethod'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'requestId': requestId,
      'consumerId': consumerId,
      'providerId': providerId,
      'totalAmount': totalAmount,
      'commissionAmount': commissionAmount,
      'providerEarnings': providerEarnings,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'paymentMethod': paymentMethod,
    };
  }
}
