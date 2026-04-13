import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/service_request_model.dart';
import '../services/firebase_service.dart';

class RequestViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<ServiceRequestModel> _incomingRequests = [];
  bool _isLoading = false;

  List<ServiceRequestModel> get incomingRequests => _incomingRequests;
  bool get isLoading => _isLoading;

  void listenToIncomingRequests(String providerId) {
    _firebaseService.getIncomingRequests(providerId).listen((requests) {
      _incomingRequests = requests;
      notifyListeners();
    });
  }

  Future<void> sendRequest({
    required String consumerId,
    required String providerId,
    required String serviceType,
    required GeoPoint location,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = ServiceRequestModel(
        requestId: const Uuid().v4(),
        consumerId: consumerId,
        providerId: providerId,
        serviceType: serviceType,
        status: RequestStatus.pending,
        timestamp: DateTime.now(),
        location: location,
      );
      await _firebaseService.createServiceRequest(request);
    } catch (e) {
      print('Error sending request: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String requestId) async {
    await _firebaseService.updateRequestStatus(requestId, RequestStatus.accepted);
  }

  Future<void> declineRequest(String requestId) async {
    await _firebaseService.updateRequestStatus(requestId, RequestStatus.declined);
  }
}
