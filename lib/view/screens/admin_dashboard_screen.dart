import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';
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
    const UsersAdminTab(),
    const PaymentsAdminTab(),
    const StatsAdminTab(),
    const ComplaintsAdminTab(),
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
          BottomNavItem(icon: Icons.group, label: 'Profiles'),
          BottomNavItem(icon: Icons.payments, label: 'Payments'),
          BottomNavItem(icon: Icons.analytics, label: 'Stats'),
          BottomNavItem(icon: Icons.report_problem, label: 'Issues'),
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
              Tab(text: "Provider Approvals"),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildServiceRequests(),
                _buildPendingProviders(context),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DateFormat('MMM dd').format(request.timestamp)),
                    if (request.status == RequestStatus.pending || request.status == RequestStatus.accepted)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance.collection('requests').doc(request.requestId).update({'status': 'cancelled'});
                        },
                      ),
                  ],
                ),
                leading: const CircleAvatar(child: Icon(Icons.build)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingProviders(BuildContext context) {
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
                      onPressed: () => _showApprovalDialog(context, provider),
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

  void _showApprovalDialog(BuildContext context, UserModel provider) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Approve Provider"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Assign a temporary password for ${provider.name}"),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                hintText: "Enter temporary password",
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password must be at least 6 characters")),
                );
                return;
              }

              try {
                // 1. Create official Firebase Auth account for the provider
                final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: provider.email,
                  password: password,
                );

                final newUid = userCredential.user!.uid;

                // 2. Map existing provider data to a new map and update keys
                final providerData = provider.toJson();
                providerData['uid'] = newUid;
                providerData['isVerified'] = true;
                providerData['isActive'] = true;

                // 3. Create a NEW document with the actual Auth UID as the Document ID
                await FirebaseFirestore.instance.collection('users').doc(newUid).set(providerData);

                // 4. Delete the old document that had the randomly generated ID
                await FirebaseFirestore.instance.collection('users').doc(provider.uid).delete();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${provider.name} approved! They can now login.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            child: const Text("Approve & Create Account"),
          ),
        ],
      ),
    );
  }
}

class UsersAdminTab extends StatelessWidget {
  const UsersAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "Active Providers"),
              Tab(text: "Consumers"),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProvidersList(),
                _buildConsumersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersList() {
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
                leading: const CircleAvatar(child: Icon(Icons.engineering)),
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

  Widget _buildConsumersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'consumer')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final consumers = snapshot.data!.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

        if (consumers.isEmpty) return const Center(child: Text('No consumers enrolled'));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: consumers.length,
          itemBuilder: (context, index) {
            final consumer = consumers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(consumer.name),
                subtitle: Text(consumer.email),
                trailing: Switch(
                  value: consumer.isActive,
                  onChanged: (val) {
                    FirebaseFirestore.instance.collection('users').doc(consumer.uid).update({'isActive': val});
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
        double payoutsDue = 0;
        double totalPayoutCompleted = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final txn = TransactionModel.fromJson(data);
          
          if (txn.status == PaymentStatus.completed) {
            totalRevenue += txn.totalAmount;
            totalCommission += txn.commissionAmount;
            if (!txn.isProviderPaid) {
              payoutsDue += txn.providerEarnings;
            } else {
              totalPayoutCompleted += txn.providerEarnings;
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatCard('Total Platform Revenue', '\$${totalRevenue.toStringAsFixed(2)}', Colors.blue, 'Gross volume from consumers'),
              const SizedBox(height: 12),
              _buildStatCard('Retained Commission', '\$${totalCommission.toStringAsFixed(2)}', Colors.green, 'Platform earnings (10%)'),
              const SizedBox(height: 12),
              _buildStatCard('Provider Payouts Due', '\$${payoutsDue.toStringAsFixed(2)}', Colors.orange, 'Funds pending transfer to providers'),
              const SizedBox(height: 12),
              _buildStatCard('Payouts Complete', '\$${totalPayoutCompleted.toStringAsFixed(2)}', Colors.purple, 'Total funds disbursed'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
              Icon(Icons.monetization_on, color: color.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class StatsAdminTab extends StatelessWidget {
  const StatsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('requests').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        int total = 0;
        int completed = 0;
        int pending = 0;
        int cancelled = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          total++;
          final status = data['status'];
          if (status == 'completed') completed++;
          else if (status == 'cancelled' || status == 'declined') cancelled++;
          else pending++;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("App Performance Analytics", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildMetricCard("Total Requests", "$total", Icons.layers),
              const SizedBox(height: 10),
              _buildMetricCard("Completed Services", "$completed", Icons.check_circle_outline, color: Colors.green),
              const SizedBox(height: 10),
              _buildMetricCard("Pending/In-Progress", "$pending", Icons.hourglass_empty, color: Colors.orange),
              const SizedBox(height: 10),
              _buildMetricCard("Cancelled/Declined", "$cancelled", Icons.cancel_outlined, color: Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, {Color color = Colors.blue}) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}

class ComplaintsAdminTab extends StatelessWidget {
  const ComplaintsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final complaints = snapshot.data!.docs.map((doc) => ComplaintModel.fromJson(doc.data() as Map<String, dynamic>)).toList();

        if (complaints.isEmpty) return const Center(child: Text('No complaints submitted.'));

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            final isOpen = complaint.status == 'open';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reported By: ${complaint.reporterId.substring(0, 5)}...', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text(complaint.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: isOpen ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(complaint.description),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM dd, hh:mm a').format(complaint.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (isOpen)
                          TextButton(
                            onPressed: () {
                              FirebaseFirestore.instance.collection('complaints').doc(complaint.complaintId).update({'status': 'resolved'});
                            },
                            child: const Text('Mark Resolved'),
                          )
                      ],
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
