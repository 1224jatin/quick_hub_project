import 'package:flutter/material.dart';
import 'home_map_screen.dart';
import '../widgets/animated_bottom_nav.dart';

class MainCustomerScreen extends StatefulWidget {
  const MainCustomerScreen({super.key});

  @override
  State<MainCustomerScreen> createState() => _MainCustomerScreenState();
}

class _MainCustomerScreenState extends State<MainCustomerScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CustomerHomeTab(),
    const HomeMapScreen(),
    const CustomerBookingsTab(),
    const CustomerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavItem(icon: Icons.home, label: 'Home'),
          BottomNavItem(icon: Icons.map, label: 'Map'),
          BottomNavItem(icon: Icons.assignment, label: 'Bookings'),
          BottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}

class CustomerHomeTab extends StatelessWidget {
  const CustomerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'Plumbing', 'icon': Icons.plumbing},
      {'name': 'Electrician', 'icon': Icons.electrical_services},
      {'name': 'Cleaning', 'icon': Icons.cleaning_services},
      {'name': 'Carpenter', 'icon': Icons.handyman},
      {'name': 'Painter', 'icon': Icons.format_paint},
      {'name': 'Mechanic', 'icon': Icons.build},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Hub Services')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () {}, // Navigate to provider list for this category
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'], size: 40, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 12),
                  Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomerBookingsTab extends StatelessWidget {
  const CustomerBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: const Center(child: Text('Your service history will appear here.')),
    );
  }
}

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Center(child: Text('Manage your account settings.')),
    );
  }
}
