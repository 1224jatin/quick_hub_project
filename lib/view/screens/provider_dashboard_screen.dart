import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import '../widgets/animated_bottom_nav.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../models/notification_model.dart';
import 'chat_screen.dart';

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
    const ProviderProfileTab(),
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
            Widget? trailingWidget;
            if (job.status == RequestStatus.completed) {
              trailingWidget = null;
            } else {
              trailingWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (job.status == RequestStatus.accepted || job.status == RequestStatus.inProgress)
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: job.requestId, otherUserId: job.consumerId)));
                      },
                    ),
                  ElevatedButton(
                    onPressed: () => _showUpdateDialog(context, job),
                    child: const Text('Update'),
                  ),
                ],
              );
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(job.serviceType),
                subtitle: Text('Status: ${job.status.name.toUpperCase()} | Payment: ${job.paymentStatus.toUpperCase()}'),
                trailing: trailingWidget,
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context, ServiceRequestModel job) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Job Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (job.status == RequestStatus.pending) ...[
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('requests').doc(job.requestId).update({'status': 'accepted'});
                    final notif = NotificationModel(
                      notificationId: const Uuid().v4(),
                      recipientId: job.consumerId,
                      title: 'Request Accepted',
                      body: 'Your request for ${job.serviceType} was accepted!',
                      timestamp: DateTime.now(),
                    );
                    await FirebaseService().saveNotification(notif);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Accept Job'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('requests').doc(job.requestId).update({'status': 'declined'});
                    final notif = NotificationModel(
                      notificationId: const Uuid().v4(),
                      recipientId: job.consumerId,
                      title: 'Request Declined',
                      body: 'Your request for ${job.serviceType} was declined.',
                      timestamp: DateTime.now(),
                    );
                    await FirebaseService().saveNotification(notif);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Decline Job'),
                ),
              ],
              if (job.status == RequestStatus.accepted) ...[
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('requests').doc(job.requestId).update({'status': 'inProgress'});
                    Navigator.pop(context);
                  },
                  child: const Text('Start Work (In Progress)'),
                ),
              ],
              if (job.status == RequestStatus.inProgress) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCompletionDialog(context, job);
                  },
                  child: const Text('Complete Job'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showCompletionDialog(BuildContext context, ServiceRequestModel job) {
    final TextEditingController hoursController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the total hours worked:'),
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'e.g., 2.5'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final double? hours = double.tryParse(hoursController.text);
                final rate = context.read<AuthViewModel>().currentUser?.hourlyRate ?? 0;
                if (hours != null && hours > 0) {
                  final total = hours * rate;
                  await FirebaseFirestore.instance.collection('requests').doc(job.requestId).update({
                    'status': 'completed',
                    'hoursWorked': hours,
                    'agreedPrice': total,
                    'paymentStatus': 'pending', 
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Submit & Generate Invoice'),
            ),
          ],
        );
      },
    );
  }
}

class ProviderEarningsTab extends StatelessWidget {
  const ProviderEarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final providerId = context.read<AuthViewModel>().currentUser?.uid;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('providerId', isEqualTo: providerId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        double totalEarnings = 0;
        for (var doc in snapshot.data!.docs) {
          totalEarnings += (doc.data() as Map<String, dynamic>)['providerEarnings'] ?? 0;
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet, size: 60, color: Colors.green),
                const SizedBox(height: 16),
                Text('Total Earnings: \$$totalEarnings', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Platform Commission (10%) has been deducted.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProviderProfileTab extends StatefulWidget {
  const ProviderProfileTab({super.key});

  @override
  State<ProviderProfileTab> createState() => _ProviderProfileTabState();
}

class _ProviderProfileTabState extends State<ProviderProfileTab> {
  final TextEditingController _rateController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final rate = context.read<AuthViewModel>().currentUser?.hourlyRate;
    if (rate != null) {
      _rateController.text = rate.toString();
    }
  }

  void _saveRate() async {
    final double? rate = double.tryParse(_rateController.text);
    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid rate')));
      return;
    }

    setState(() => _isLoading = true);
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'hourlyRate': rate});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hourly rate updated')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile: ${user?.name ?? ""}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Set Hourly Rate (INR)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. 500'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRate,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save'),
              )
            ],
          ),
        ],
      ),
    );
  }
}
