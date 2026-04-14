import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../view_models/map_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/request_view_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().fetchProviders();
    });
  }

  void _showProviderDetails(UserModel provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                provider.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.serviceType ?? 'General Service',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.rating} (${provider.reviewCount} reviews)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  const Text('•'),
                  const SizedBox(width: 16),
                  Text(
                    '\$${provider.hourlyRate ?? 0}/hr',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.bio != null) ...[
                Text(
                  provider.bio!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _sendRequest(provider),
                  child: const Text('Send Service Request'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendRequest(UserModel provider) {
    if (provider.location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider location is unknown!')),
      );
      return;
    }
    
    final consumerId = context.read<AuthViewModel>().currentUser?.uid;
    if (consumerId != null) {
      context.read<RequestViewModel>().sendRequest(
            consumerId: consumerId,
            providerId: provider.uid,
            serviceType: provider.serviceType ?? 'General',
            location: GeoPoint(provider.location!.latitude, provider.location!.longitude),
          );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service request sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Consumer<MapViewModel>(
            builder: (context, mapViewModel, child) {
              final position = mapViewModel.currentPosition ?? const LatLng(37.7749, -122.4194);
              
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.quickhub.app',
                  ),
                  MarkerLayer(
                    markers: [
                      if (mapViewModel.currentPosition != null)
                        Marker(
                          point: mapViewModel.currentPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ...mapViewModel.nearbyProviders.map((provider) {
                        if (provider.location == null) return null;
                        return Marker(
                          point: LatLng(provider.location!.latitude, provider.location!.longitude),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showProviderDetails(provider),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.build, color: Colors.white, size: 20),
                            ),
                          ),
                        );
                      }).whereType<Marker>(),
                    ],
                  ),
                ],
              );
            },
          ),
          
          // Simplified top bar for the map tab
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Text('Search for services...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16), // Adjust if needed to not overlap with bottom nav
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          mini: true,
          child: const Icon(Icons.my_location),
          onPressed: () {
            final position = context.read<MapViewModel>().currentPosition;
            if (position != null) {
              _mapController.move(position, 15.0);
            }
          },
        ),
      ),
    );
  }
}
