import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

class MapViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  
  LatLng? _currentPosition;
  List<UserModel> _nearbyProviders = [];

  LatLng? get currentPosition => _currentPosition;
  List<UserModel> get nearbyProviders => _nearbyProviders;

  MapViewModel() {
    _initLocation();
    _fetchProviders();
  }

  Future<void> _initLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      notifyListeners();
    }
  }

  void _fetchProviders() {
    _firebaseService.getNearbyActiveProviders().listen((providers) {
      _nearbyProviders = providers;
      notifyListeners();
    });
  }
}
