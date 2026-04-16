import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

class MapViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  
  LatLng? _currentPosition;
  List<UserModel> _allProviders = [];
  List<UserModel> _filteredProviders = [];
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedCategory;

  LatLng? get currentPosition => _currentPosition;
  List<UserModel> get nearbyProviders => _filteredProviders;
  bool get isSearching => _isSearching;

  MapViewModel() {
    _initLocation();
    _listenToProviders();
  }

  Future<void> _initLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      _currentPosition = LatLng(position.latitude, position.longitude);
      
      // Update the user's location in Firestore if they are logged in
      final uid = _firebaseService.currentUserId;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'location': GeoPoint(position.latitude, position.longitude),
        });
      }
      
      notifyListeners();
    }
  }

  void _listenToProviders() {
    _firebaseService.getNearbyActiveProviders().listen((providers) {
      _allProviders = providers;
      _applyFilters();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredProviders = _allProviders.where((provider) {
      final matchesQuery = provider.name.toLowerCase().contains(_searchQuery) || 
                          (provider.serviceType?.toLowerCase().contains(_searchQuery) ?? false);
      final matchesCategory = _selectedCategory == null || provider.serviceType == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    await _initLocation();
  }
}
