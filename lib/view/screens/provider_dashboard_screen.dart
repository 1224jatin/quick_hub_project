import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import '../../models/transaction_model.dart';
import '../widgets/animated_bottom_nav.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/firebase_service.dart';
import '../../models/notification_model.dart';
import 'chat_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProviderJobsTab(),
    const ProviderServicesTab(),
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

class ProviderServicesTab extends StatefulWidget {
  const ProviderServicesTab({super.key});

  @override
  State<ProviderServicesTab> createState() => _ProviderServicesTabState();
}

class _ProviderServicesTabState extends State<ProviderServicesTab> {
  final _bioController = TextEditingController();
  String? _selectedCategory;
  bool _isActive = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Plumbing', 'Electric', 'Cleaning', 'Mechanic', 'Painter', 'Carpenter', 'Gardening'
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      _bioController.text = user.bio ?? '';
      _isActive = user.isActive;
      if (_categories.contains(user.serviceType)) {
        _selectedCategory = user.serviceType;
      }
    }
  }

  void _saveProfile() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'bio': _bioController.text.trim(),
        'serviceType': _selectedCategory,
        'isActive': _isActive,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('My Services & Availability', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SwitchListTile(
                title: const Text('Available for Jobs (Active)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Turn off to hide your profile from the consumer map.'),
                value: _isActive,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() => _isActive = val);
                  final user = context.read<AuthViewModel>().currentUser;
                  if (user != null) {
                    FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isActive': val});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Primary Service Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Professional Bio',
              hintText: 'Tell customers about your experience and skills...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 30),
          
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Save Profile Details', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 100),
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
        if (!snapshot.hasData) {
          return ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Container(width: double.infinity, height: 16, color: Colors.white),
                    subtitle: Container(width: 150, height: 14, color: Colors.white),
                    trailing: Container(width: 40, height: 40, color: Colors.white),
                  ),
                ),
              );
            },
          );
        }
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
                  SizedBox(
                    width: 100,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => _showUpdateDialog(context, job),
                      child: const Text('Update'),
                    ),
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
        if (!snapshot.hasData) {
          return Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                margin: const EdgeInsets.all(20),
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)
                ),
              ),
            ),
          );
        }
        
        final txns = snapshot.data!.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
        txns.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        double totalEarnings = 0;
        List<FlSpot> spots = [];
        double index = 0;

        for (var txn in txns) {
          totalEarnings += txn.providerEarnings;
          spots.add(FlSpot(index, totalEarnings));
          index++;
        }

        if (spots.isEmpty) {
          spots.add(const FlSpot(0, 0));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Earnings Analytics',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Total Earnings', style: TextStyle(color: Colors.grey)),
                    Text('\$${totalEarnings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text('Revenue Growth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
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

  Future<void> _generatePdfReport(BuildContext context, dynamic userModel) async {
    if (userModel == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('providerId', isEqualTo: userModel.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      final txns = snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
      txns.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first

      double totalEarnings = 0;
      for (var t in txns) totalEarnings += t.providerEarnings;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Earnings Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Provider: ${userModel.name}'),
                pw.Text('Generated On: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
                pw.SizedBox(height: 20),
                pw.Text('Total Earnings: \$${totalEarnings.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, color: PdfColors.green)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Type', 'Amount'],
                  data: txns.map((t) => [
                    DateFormat('yyyy-MM-dd').format(t.timestamp),
                    'Service Payout',
                    '\$${t.providerEarnings.toStringAsFixed(2)}'
                  ]).toList(),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/earnings_report_${userModel.uid}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Generated Successfully')));
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final isPremium = user?.isPremium ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Profile: ${user?.name ?? ""}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (isPremium) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ]
            ],
          ),
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
              SizedBox(
                width: 100,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: _isLoading ? null : _saveRate,
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
              )
            ],
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export Earnings Report'),
            subtitle: const Text('Download a PDF summary of all earnings.'),
            trailing: const Icon(Icons.download),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
              await _generatePdfReport(context, user);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300)
            ),
          )
        ],
      ),
    );
  }
}
