import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
    GeoPoint? updatedLocation = user.location;
    
    if (_isActive) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (serviceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
          updatedLocation = GeoPoint(position.latitude, position.longitude);
        }
      } catch (e) {
        debugPrint("Location error: $e");
      }
    }

    try {
      final updateData = <String, dynamic>{
        'bio': _bioController.text.trim(),
        'serviceType': _selectedCategory,
        'isActive': _isActive,
      };
      if (updatedLocation != null) {
        updateData['location'] = updatedLocation;
      }
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
      
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
                onChanged: (val) async {
                  setState(() => _isActive = val);
                  final user = context.read<AuthViewModel>().currentUser;
                  if (user != null) {
                    GeoPoint? loc = user.location;
                    if (val) {
                      try {
                        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                        LocationPermission permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }
                        if (serviceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
                          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                          loc = GeoPoint(position.latitude, position.longitude);
                        }
                      } catch (e) {
                        debugPrint("Location error: $e");
                      }
                    }
                    final updateData = <String, dynamic>{'isActive': val};
                    if (loc != null) updateData['location'] = loc;
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
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
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _rateController = TextEditingController();
  final _bioController = TextEditingController();
  final _houseController = TextEditingController();
  final _buildingController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String? _gender;
  String? _language;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _ageController.text = user.age?.toString() ?? '';
      _rateController.text = user.hourlyRate?.toString() ?? '';
      _bioController.text = user.bio ?? '';
      _houseController.text = user.houseNo ?? '';
      _buildingController.text = user.buildingName ?? '';
      _landmarkController.text = user.landmark ?? '';
      _cityController.text = user.city ?? '';
      _stateController.text = user.state ?? '';
      _gender = user.gender;
      _language = user.preferredLanguage;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    
    if (user != null) {
      final fullAddress = "${_houseController.text}, ${_buildingController.text}, ${_landmarkController.text}, ${_cityController.text}, ${_stateController.text}";
      
      final updatedUser = UserModel(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: user.email,
        role: user.role,
        createdAt: user.createdAt,
        age: int.tryParse(_ageController.text),
        gender: _gender,
        preferredLanguage: _language,
        hourlyRate: double.tryParse(_rateController.text),
        bio: _bioController.text.trim(),
        houseNo: _houseController.text.trim(),
        buildingName: _buildingController.text.trim(),
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        fullAddress: fullAddress,
        isActive: user.isActive,
        isVerified: user.isVerified,
        isPremium: user.isPremium,
        location: user.location,
        serviceType: user.serviceType,
        rating: user.rating,
        reviewCount: user.reviewCount,
        aadhaarNumber: user.aadhaarNumber,
        panNumber: user.panNumber,
      );

      final success = await authVM.updateProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Profile updated successfully!' : 'Update failed.')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _useGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _houseController.text = p.name ?? '';
          _buildingController.text = p.subLocality ?? '';
          _landmarkController.text = p.thoroughfare ?? '';
          _cityController.text = p.locality ?? '';
          _stateController.text = p.administrativeArea ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch location.')));
    }
  }

  Future<void> _generatePdfReport(BuildContext context, UserModel userModel) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('providerId', isEqualTo: userModel.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      final txns = snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
      txns.sort((a, b) => b.timestamp.compareTo(a.timestamp));

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Generated Successfully')));
        OpenFile.open(file.path);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(radius: 50, backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.person, size: 50, color: Colors.blue)),
                if (user.isPremium)
                  const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 14, backgroundColor: Colors.amber, child: Icon(Icons.star, size: 16, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          const SizedBox(height: 10),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()))),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: ['Male', 'Female', 'Other'].contains(_gender) ? _gender : null,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _gender = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: ['English', 'Hindi', 'Punjabi', 'Other'].contains(_language) ? _language : null,
            decoration: const InputDecoration(labelText: 'Preferred Language', border: OutlineInputBorder()),
            items: ['English', 'Hindi', 'Punjabi', 'Other'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (val) => setState(() => _language = val),
          ),
          const SizedBox(height: 24),
          const Text('Verification (Read-Only)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          const SizedBox(height: 10),
          TextField(decoration: const InputDecoration(labelText: 'Aadhaar Number', border: OutlineInputBorder()), controller: TextEditingController(text: user.aadhaarNumber ?? 'Pending Verification'), readOnly: true, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(labelText: 'PAN Number', border: OutlineInputBorder()), controller: TextEditingController(text: user.panNumber ?? 'Pending Verification'), readOnly: true, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          const Text('Professional Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          const SizedBox(height: 10),
          TextField(controller: _rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hourly Rate (INR)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio / Skills', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Location Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _useGPS, icon: const Icon(Icons.my_location), label: const Text('Use GPS')),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          TextField(controller: _houseController, decoration: const InputDecoration(labelText: 'House/Flat No.', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _buildingController, decoration: const InputDecoration(labelText: 'Building/Area', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _landmarkController, decoration: const InputDecoration(labelText: 'Landmark', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Profile'),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export Earnings Report'),
            trailing: const Icon(Icons.download),
            onTap: () => _generatePdfReport(context, user),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
