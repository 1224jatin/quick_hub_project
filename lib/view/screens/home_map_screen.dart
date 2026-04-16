import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../view_models/map_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/request_view_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../models/notification_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'provider_details_screen.dart';

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
    // No need to manually fetch here, MapViewModel does it in its constructor and listens to changes
  }

  void _navigateToProviderDetails(UserModel provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderDetailsScreen(provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.quick_hub_project',
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
                          onTap: () => _navigateToProviderDetails(provider),
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
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) => context.read<MapViewModel>().setSearchQuery(value),
                    decoration: const InputDecoration(
                      hintText: 'Search for services...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Manually positioned Floating Action Button
        Positioned(
          right: 20,
          bottom: 120, // Positioned above the bottom navigation bar
          child: FloatingActionButton(
            heroTag: 'map_fab',
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
      ],
    );
  }
}
