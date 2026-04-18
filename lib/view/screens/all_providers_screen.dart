import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/map_view_model.dart';
import 'provider_details_screen.dart';
import '../../core/theme.dart';

class AllProvidersScreen extends StatelessWidget {
  const AllProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    // Use allNearbyProviders to show all irrespective of currently selected category
    final providers = mapVM.allNearbyProviders;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nearby Professionals'),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: providers.isEmpty
          ? Center(
              child: Text(
                "No providers found in your area.",
                style: TextStyle(color: isDark ? AppTheme.baseWhite : Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: isDark ? AppTheme.darkSurface : AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? AppTheme.baseWhite.withOpacity(0.1) : Colors.grey.shade200,
                    ),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProviderDetailsScreen(provider: provider)),
                      );
                    },
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBackground : AppTheme.primaryLightBlue,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.person, 
                        color: isDark ? AppTheme.baseWhite : AppTheme.primaryDarkBlue, 
                        size: 30
                      ),
                    ),
                    title: Text(
                      provider.name, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.baseWhite : Colors.black,
                      )
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.serviceType ?? 'General Service', 
                          style: TextStyle(color: theme.primaryColor)
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                              ' ${provider.rating.toStringAsFixed(1)} (${provider.reviewCount} reviews)', 
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${provider.hourlyRate ?? 0}/hr', 
                          style: const TextStyle(
                            color: Colors.green, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16
                          )
                        ),
                        Icon(
                          Icons.chevron_right, 
                          color: isDark ? Colors.grey.shade600 : Colors.grey
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
