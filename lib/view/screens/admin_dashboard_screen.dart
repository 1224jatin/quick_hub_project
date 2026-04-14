import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.engineering), label: 'Providers'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
        ],
      ),
    );
  }
}

// ---------------- REQUESTS TAB ----------------

class RequestsAdminTab extends StatelessWidget {
  const RequestsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final requests = snapshot.data!.docs.map((doc) => ServiceRequestModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${request.serviceType} Request'),
                subtitle: Text('Status: ${request.status.name.toUpperCase()}'),
                trailing: Text(DateFormat('MMM dd').format(request.timestamp)),
                leading: CircleAvatar(child: Icon(_getIcon(request.serviceType))),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'plumber': return Icons.plumbing;
      case 'electrician': return Icons.electrical_services;
      default: return Icons.build;
    }
  }
}

// ---------------- PAYMENTS TAB ----------------

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
              _buildStatCard('Total Commission (10%)', '\$${totalCommission.toStringAsFixed(2)}', Colors.green),
              const SizedBox(height: 24),
              const Expanded(child: Center(child: Text('Detailed Transaction History Below'))),
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

// ---------------- PROVIDERS TAB ----------------

class ProvidersAdminTab extends StatelessWidget {
  const ProvidersAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'provider').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final providers = snapshot.data!.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

        return ListView.builder(
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final provider = providers[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(provider.name),
              subtitle: Text(provider.serviceType ?? 'No Service Set'),
              trailing: Switch(
                value: provider.isVerified,
                onChanged: (val) {
                  FirebaseFirestore.instance.collection('users').doc(provider.uid).update({'isVerified': val});
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------- STATS TAB ----------------

class StatsAdminTab extends StatelessWidget {
  const StatsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Platform Analytics & Growth Charts'));
  }
}
