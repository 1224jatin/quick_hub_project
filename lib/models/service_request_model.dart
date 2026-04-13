import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, declined, inProgress, completed, cancelled }

class ServiceRequestModel {
  final String requestId;
  final String consumerId;
  final String providerId;
  final String serviceType;
  final String? description;
  final double? agreedPrice;
  final RequestStatus status;
  final DateTime timestamp;
  final DateTime? scheduledDate;
  final GeoPoint location;

  ServiceRequestModel({
    required this.requestId,
    required this.consumerId,
    required this.providerId,
    required this.serviceType,
    this.description,
    this.agreedPrice,
    required this.status,
    required this.timestamp,
    this.scheduledDate,
    required this.location,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    RequestStatus parsedStatus;
    switch (json['status']) {
      case 'accepted': parsedStatus = RequestStatus.accepted; break;
      case 'declined': parsedStatus = RequestStatus.declined; break;
      case 'inProgress': parsedStatus = RequestStatus.inProgress; break;
      case 'completed': parsedStatus = RequestStatus.completed; break;
      case 'cancelled': parsedStatus = RequestStatus.cancelled; break;
      default: parsedStatus = RequestStatus.pending;
    }

    return ServiceRequestModel(
      requestId: json['requestId'] as String,
      consumerId: json['consumerId'] as String,
      providerId: json['providerId'] as String,
      serviceType: json['serviceType'] as String,
      description: json['description'] as String?,
      agreedPrice: (json['agreedPrice'] as num?)?.toDouble(),
      status: parsedStatus,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      scheduledDate: (json['scheduledDate'] as Timestamp?)?.toDate(),
      location: json['location'] as GeoPoint,
    );
  }

  Map<String, dynamic> toJson() {
    String statusString;
    switch (status) {
      case RequestStatus.accepted: statusString = 'accepted'; break;
      case RequestStatus.declined: statusString = 'declined'; break;
      case RequestStatus.inProgress: statusString = 'inProgress'; break;
      case RequestStatus.completed: statusString = 'completed'; break;
      case RequestStatus.cancelled: statusString = 'cancelled'; break;
      default: statusString = 'pending';
    }

    return {
      'requestId': requestId,
      'consumerId': consumerId,
      'providerId': providerId,
      'serviceType': serviceType,
      'description': description,
      'agreedPrice': agreedPrice,
      'status': statusString,
      'timestamp': Timestamp.fromDate(timestamp),
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'location': location,
    };
  }
}
