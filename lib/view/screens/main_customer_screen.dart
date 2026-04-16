import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/razorpay_service.dart';
import '../../services/firebase_service.dart';
import 'home_map_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'provider_details_screen.dart';
import '../widgets/animated_bottom_nav.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/map_view_model.dart';
import '../../core/theme.dart';
import '../../models/complaint_model.dart';
import '../../models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MainCustomerScreen extends StatefulWidget {
  const MainCustomerScreen({super.key});

  @override
  State<MainCustomerScreen> createState() => _MainCustomerScreenState();
}

class _MainCustomerScreenState extends State<MainCustomerScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mapVM = context.watch<MapViewModel>();
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              const CustomerHomeTab(),
              const HomeMapScreen(),
              const CustomerBookingsTab(),
              const CustomerProfileTab(),
            ],
          ),
          if (mapVM.isFetchingLocation)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulseAnimation(),
                    const SizedBox(height: 20),
                    const Text(
                      "Fetching current location...",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedIndex,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
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

class PulseAnimation extends StatefulWidget {
  const PulseAnimation({super.key});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryLightBlue.withOpacity(1 - _controller.value),
            border: Border.all(
              color: AppTheme.primaryDarkBlue.withOpacity(1 - _controller.value),
              width: 4 * _controller.value,
            ),
          ),
          child: const Center(
            child: Icon(Icons.location_on, color: AppTheme.primaryDarkBlue, size: 30),
          ),
        );
      },
    );
  }
}

class CustomerHomeTab extends StatelessWidget {
  const CustomerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
    final mapVM = context.watch<MapViewModel>();
    final userName = authVM.currentUser?.name ?? 'Guest';

    final List<Map<String, dynamic>> promoCards = [
      {
        'title': 'Best Services',
        'desc': 'Professional help for your home\njust a tap away.',
        'gradient': [AppTheme.primaryDarkBlue, const Color(0xFF1E3A8A)],
        'icon': Icons.stars,
      },
      {
        'title': 'Home Sparkle Deal',
        'desc': 'Get 30% off on full home\ncleaning services this week.',
        'gradient': [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
        'icon': Icons.cleaning_services,
      },
    ];

    final List<Map<String, dynamic>> categories = [
      {'name': 'Plumbing', 'icon': Icons.plumbing},
      {'name': 'Electric', 'icon': Icons.bolt},
      {'name': 'Cleaning', 'icon': Icons.cleaning_services},
      {'name': 'Mechanic', 'icon': Icons.build},
      {'name': 'Painter', 'icon': Icons.format_paint},
    ];

    return Container(
      color: isDark ? AppTheme.darkBackground : const Color(0xFFFBFBFF),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: theme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello $userName',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.primaryDarkBlue,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => mapVM.fetchLocation(force: true),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.5,
                                  child: Text(
                                    mapVM.locationError ?? (mapVM.currentAddress ?? "Fetching location..."),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: mapVM.locationError != null ? Colors.red : Colors.grey,
                                      decoration: TextDecoration.underline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                        ],
                      ),
                      child: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : AppTheme.primaryDarkBlue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 55,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) => context.read<MapViewModel>().setSearchQuery(value),
                        decoration: InputDecoration(
                          hintText: 'Search Service',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          icon: Icon(Icons.search, color: Colors.grey.shade400),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      // Filter dialog could be added here
                    },
                    child: Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                        ],
                      ),
                      child: Icon(Icons.tune_rounded, color: theme.primaryColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Horizontal Sliding Promo Cards
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: promoCards.length,
                  itemBuilder: (context, index) {
                    final card = promoCards[index];
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.82,
                      margin: const EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: card['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (card['gradient'] as List<Color>)[0].withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(25.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card['title'],
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card['desc'],
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(card['icon'], size: 120, color: Colors.white.withOpacity(0.15)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Categories Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('See All', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              // Horizontal Categories
              SizedBox(
                height: 105,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.read<MapViewModel>().setCategory(cat['name']);
                            },
                            child: Container(
                              height: 65,
                              width: 65,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.primaryLightBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(cat['icon'], color: AppTheme.primaryDarkBlue, size: 28),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cat['name'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // Nearby Providers Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nearby Providers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('See All', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Nearby Providers Grid/List
              SizedBox(
                height: 220,
                child: mapVM.nearbyProviders.isEmpty 
                  ? const Center(child: Text("No providers found in this area."))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mapVM.nearbyProviders.length,
                      itemBuilder: (context, index) {
                        final provider = mapVM.nearbyProviders[index];
                        return _buildProviderCard(context, provider);
                      },
                    ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, UserModel provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDetailsScreen(provider: provider),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15, bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryLightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.person, color: AppTheme.primaryDarkBlue, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              provider.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              provider.serviceType ?? 'General',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(' ${provider.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text('\$${provider.hourlyRate ?? 0}/hr', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerBookingsTab extends StatefulWidget {
  const CustomerBookingsTab({super.key});

  @override
  State<CustomerBookingsTab> createState() => _CustomerBookingsTabState();
}

class _CustomerBookingsTabState extends State<CustomerBookingsTab> {
  late final RazorpayService _razorpayService;
  String? _processingRequestId;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.onSuccess = _handlePaymentSuccess;
    _razorpayService.onFailure = _handlePaymentError;
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_processingRequestId == null) return;
    
    final authVM = context.read<AuthViewModel>();
    final consumerId = authVM.currentUser!.uid;

    try {
      final doc = await FirebaseFirestore.instance.collection('requests').doc(_processingRequestId).get();
      final data = doc.data()!;
      final totalAmount = (data['agreedPrice'] as num).toDouble();
      final providerId = data['providerId'];

      await FirebaseService().processPayment(
        requestId: _processingRequestId!,
        consumerId: consumerId,
        providerId: providerId,
        totalAmount: totalAmount,
        paymentMethod: 'Razorpay',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error recording payment: $e')));
      }
    } finally {
      _processingRequestId = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _processingRequestId = null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}')));
  }

  void _startPayment(BuildContext context, String requestId, double amount) {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;

    _processingRequestId = requestId;

    _razorpayService.openCheckout(
      amount: amount,
      name: 'Quick Hub Services',
      description: 'Payment for completed service',
      contact: '9999999999',
      email: user.email,
    );
  }

  void _showComplaintDialog(BuildContext context, String requestId, String accusedId) {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report an Issue'),
          content: TextField(
            controller: textController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe the problem clearly...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                
                final consumerId = context.read<AuthViewModel>().currentUser?.uid;
                if (consumerId != null) {
                  final complaint = ComplaintModel(
                    complaintId: const Uuid().v4(),
                    reporterId: consumerId,
                    accusedId: accusedId,
                    requestId: requestId,
                    description: text,
                    timestamp: DateTime.now(),
                  );
                  await FirebaseService().submitComplaint(complaint);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully.')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final consumerId = context.read<AuthViewModel>().currentUser?.uid;
    if (consumerId == null) return const Center(child: Text("Please Login to see bookings."));

    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('My Bookings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('requests')
                .where('consumerId', isEqualTo: consumerId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final bookings = snapshot.data!.docs;

              if (bookings.isEmpty) return const Center(child: Text('You have no bookings.'));

              return ListView.builder(
                itemCount: bookings.length,
                padding: const EdgeInsets.only(bottom: 100),
                itemBuilder: (context, index) {
                  final data = bookings[index].data() as Map<String, dynamic>;
                  final requestId = bookings[index].id;
                  final serviceType = data['serviceType'] ?? 'Service';
                  final status = data['status'] ?? 'pending';
                  final paymentStatus = data['paymentStatus'] ?? 'pending';
                  final agreedPrice = (data['agreedPrice'] as num?)?.toDouble() ?? 0.0;
                  final providerId = data['providerId'];

                  Widget trailingWidget;
                  if (status == 'completed' && paymentStatus == 'pending') {
                    trailingWidget = ElevatedButton(
                      onPressed: () => _startPayment(context, requestId, agreedPrice),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('Pay \$${agreedPrice.toStringAsFixed(2)}'),
                    );
                  } else if (paymentStatus == 'paid') {
                    trailingWidget = const Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
                  } else if (status == 'accepted' || status == 'inProgress') {
                    trailingWidget = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: requestId, otherUserId: providerId)));
                          },
                        ),
                        Text(status.toUpperCase(), style: const TextStyle(fontSize: 12)),
                      ],
                    );
                  } else {
                    trailingWidget = Text(status.toUpperCase());
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(serviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Status: ${status.toUpperCase()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          trailingWidget,
                          IconButton(
                            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            onPressed: () => _showComplaintDialog(context, requestId, providerId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  final _nameController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _buildingController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  GeoPoint? _currentLocation;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _houseNoController.text = user.houseNo ?? '';
      _buildingController.text = user.buildingName ?? '';
      _landmarkController.text = user.landmark ?? '';
      _cityController.text = user.city ?? '';
      _stateController.text = user.state ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _gender = user.gender;
      _currentLocation = user.location;
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile'),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProfile();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    if (user != null) {
      final fullAddress = "${_houseNoController.text}, ${_buildingController.text}, ${_landmarkController.text}, ${_cityController.text}, ${_stateController.text}";
      
      final updatedUser = UserModel(
        uid: user.uid,
        name: _nameController.text,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt,
        houseNo: _houseNoController.text,
        buildingName: _buildingController.text,
        landmark: _landmarkController.text,
        city: _cityController.text,
        state: _stateController.text,
        fullAddress: fullAddress,
        age: int.tryParse(_ageController.text),
        gender: _gender,
        isActive: user.isActive,
        profileImage: user.profileImage,
        location: _currentLocation ?? user.location,
      );
      
      final success = await authVM.updateProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Profile updated successfully!' : 'Failed to update profile.')),
        );
      }
    }
  }

  Future<void> _useGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      
      setState(() {
        _currentLocation = GeoPoint(position.latitude, position.longitude);
        _houseNoController.text = place.name ?? '';
        _buildingController.text = place.subLocality ?? '';
        _landmarkController.text = place.thoroughfare ?? '';
        _cityController.text = place.locality ?? '';
        _stateController.text = place.administrativeArea ?? '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location fetched successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to fetch location.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () => context.read<AuthViewModel>().logout(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Location Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _useGPS,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use GPS'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _houseNoController,
                  decoration: const InputDecoration(labelText: 'House No. / Flat No.', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _buildingController,
                  decoration: const InputDecoration(labelText: 'Building Name / Apartment', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(labelText: 'Landmark', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _stateController,
                        decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _showConfirmationDialog,
                    child: const Text('Save Profile'),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
