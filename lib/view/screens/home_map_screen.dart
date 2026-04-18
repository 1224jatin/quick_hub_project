import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../view_models/map_view_model.dart';
import '../../models/user_model.dart';
import '../../core/theme.dart';
import 'provider_details_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final MapController _mapController = MapController();

  void _navigateToProviderDetails(UserModel provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderDetailsScreen(provider: provider),
      ),
    );
  }

  IconData _getServiceIcon(String? type) {
    type = type?.toLowerCase() ?? '';
    if (type.contains('plumb')) return Icons.plumbing;
    if (type.contains('elect')) return Icons.bolt;
    if (type.contains('clean')) return Icons.cleaning_services;
    if (type.contains('mech')) return Icons.build;
    if (type.contains('paint')) return Icons.format_paint;
    if (type.contains('carpenter')) return Icons.handyman;
    if (type.contains('garden')) return Icons.yard;
    return Icons.person_pin_circle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        Consumer<MapViewModel>(
          builder: (context, mapViewModel, child) {
            final position = mapViewModel.currentPosition ?? const LatLng(30.7333, 76.7794); 
            
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
                        width: 60,
                        height: 60,
                        child: _buildUserLocationMarker(),
                      ),
                    
                    ...mapViewModel.nearbyProviders.map((provider) {
                      if (provider.location == null) return null;
                      return Marker(
                        point: LatLng(provider.location!.latitude, provider.location!.longitude),
                        width: 100, // Increased width for the initial
                        height: 70,
                        child: _buildProviderMarker(provider),
                      );
                    }).whereType<Marker>(),
                  ],
                ),
              ],
            );
          },
        ),
        
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: TextField(
              onChanged: (value) => context.read<MapViewModel>().setSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'Search for nearby experts...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        Positioned(
          right: 20,
          bottom: 120,
          child: Column(
            children: [
              _buildMapControlFab(
                icon: Icons.add,
                onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
              ),
              const SizedBox(height: 10),
              _buildMapControlFab(
                icon: Icons.remove,
                onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
              ),
              const SizedBox(height: 10),
              _buildMapControlFab(
                icon: Icons.my_location,
                color: theme.primaryColor,
                iconColor: Colors.white,
                onPressed: () {
                  final pos = context.read<MapViewModel>().currentPosition;
                  if (pos != null) _mapController.move(pos, 15.0);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.2),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderMarker(UserModel provider) {
    final theme = Theme.of(context);
    final icon = _getServiceIcon(provider.serviceType);
    final initial = provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => _navigateToProviderDetails(provider),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey.shade100,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    if (provider.isPremium) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
          CustomPaint(
            size: const Size(12, 8),
            painter: TrianglePainter(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlFab({required IconData icon, required VoidCallback onPressed, Color? color, Color? iconColor}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 20),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
