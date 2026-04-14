import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import '../widgets/animated_bottom_nav.dart';
import 'package:intl/intl.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProviderJobsTab(),
    const Center(child: Text('My Services & Availability')),
    const ProviderEarningsTab(),
    const Center(child: Text('Profile Management')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavItem(icon: Icons.list_alt, label: 'Jobs'),
          BottomNavItem(icon: Icons.build, label: 'Services'),
          BottomNavItem(icon: Icons.payments, label: 'Earnings'),
          BottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}

class ProviderJobsTab extends StatelessWidget {
  const ProviderJobsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final providerId = context.read<AuthViewModel>().currentUser?.uid;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('providerId', isEqualTo: providerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final jobs = snapshot.data!.docs.map((doc) => ServiceRequestModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

        if (jobs.isEmpty) return const Center(child: Text('No assigned jobs yet.'));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(job.serviceType),
                subtitle: Text('Status: ${job.status.name.toUpperCase()}'),
                trailing: ElevatedButton(
                  onPressed: () {}, // Update job status
                  child: const Text('Update'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProviderEarningsTab extends StatelessWidget {
  const ProviderEarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 60, color: Colors.green),
            SizedBox(height: 16),
            Text('Total Earnings: \$0.00', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Platform Commission (10%) will be deducted.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
