import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../widgets/animated_bottom_nav.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const RequestsAdminTab(),
    const PaymentsAdminTab(),
    const ProvidersAdminTab(),
    const StatsAdminTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavItem(icon: Icons.assignment, label: 'Requests'),
          BottomNavItem(icon: Icons.payments, label: 'Payments'),
          BottomNavItem(icon: Icons.engineering, label: 'Providers'),
          BottomNavItem(icon: Icons.analytics, label: 'Stats'),
        ],
      ),
    );
  }
}

class RequestsAdminTab extends StatelessWidget {
  const RequestsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "Service Requests"),
              Tab(text: "Provider Requests"),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildServiceRequests(),
                _buildPendingProviders(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs.map((doc) => ServiceRequestModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${request.serviceType} Request'),
                subtitle: Text('Status: ${request.status.name.toUpperCase()}'),
                trailing: Text(DateFormat('MMM dd').format(request.timestamp)),
                leading: const CircleAvatar(child: Icon(Icons.build)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingProviders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('isVerified', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final providers = snapshot.data!.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

        if (providers.isEmpty) return const Center(child: Text('No pending provider requests'));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final provider = providers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(provider.name),
                subtitle: Text('${provider.serviceType} | ${provider.city}, ${provider.state}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('users').doc(provider.uid).update({
                          'isVerified': true,
                          'isActive': true,
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('users').doc(provider.uid).delete();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PaymentsAdminTab extends StatelessWidget {
  const PaymentsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        double totalRevenue = 0;
        double totalCommission = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalRevenue += (data['totalAmount'] ?? 0);
          totalCommission += (data['commissionAmount'] ?? 0);
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStatCard('Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}', Colors.blue),
              const SizedBox(height: 16),
              _buildStatCard('Total Commission', '\$${totalCommission.toStringAsFixed(2)}', Colors.green),
              const Expanded(child: Center(child: Text('Detailed Transaction History'))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class ProvidersAdminTab extends StatelessWidget {
  const ProvidersAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .where('isVerified', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final providers = snapshot.data!.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

        if (providers.isEmpty) return const Center(child: Text('No active providers'));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final provider = providers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(provider.name),
                subtitle: Text(provider.serviceType ?? 'No Service'),
                trailing: Switch(
                  value: provider.isActive,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection('users').doc(provider.uid).update({'isActive': val});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class StatsAdminTab extends StatelessWidget {
  const StatsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Analytics & Stats'));
  }
}
