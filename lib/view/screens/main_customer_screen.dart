import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/razorpay_service.dart';
import '../../services/firebase_service.dart';
import 'home_map_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import '../widgets/animated_bottom_nav.dart';
import '../../view_models/auth_view_model.dart';
import '../../core/theme.dart';
import '../../models/complaint_model.dart';
import 'package:uuid/uuid.dart';

class MainCustomerScreen extends StatefulWidget {
  const MainCustomerScreen({super.key});

  @override
  State<MainCustomerScreen> createState() => _MainCustomerScreenState();
}

class _MainCustomerScreenState extends State<MainCustomerScreen> {
  int _selectedIndex = 0;
  String _currentAddress = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentAddress = "Location services disabled");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentAddress = "Permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _currentAddress = "Location permission permanently denied");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      
      setState(() {
        _currentAddress = "${place.subLocality}, ${place.locality}";
      });
    } catch (e) {
      setState(() => _currentAddress = "Address not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CustomerHomeTab(currentAddress: _currentAddress),
          const HomeMapScreen(),
          const CustomerBookingsTab(),
          const CustomerProfileTab(),
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

class CustomerHomeTab extends StatelessWidget {
  final String currentAddress;
  const CustomerHomeTab({super.key, required this.currentAddress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authVM = context.watch<AuthViewModel>();
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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFFBFBFF),
      body: SafeArea(
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
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                currentAddress,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                            ],
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
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey.shade400),
                          const SizedBox(width: 10),
                          Text('Search Service', style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
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
                          Container(
                            height: 65,
                            width: 65,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.primaryLightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(cat['icon'], color: AppTheme.primaryDarkBlue, size: 28),
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
              
              // Nearby Providers Grid/List (Horizontal as per reference)
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildProviderCard(context, 'John Maskur', 'Plumbing', 4.5, 4),
                    _buildProviderCard(context, 'Sarah Wyne', 'Cleaning', 4.8, 3),
                    _buildProviderCard(context, 'Alex Smith', 'Electric', 4.2, 5),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, String name, String service, double rating, int exp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            service,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  Text(' $rating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Text('$exp yrs', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
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
    
    // Payment Successful, record in backend
    final authVM = context.read<AuthViewModel>();
    final consumerId = authVM.currentUser!.uid;

    try {
      // In a real app we'd fetch the exact exact amount securely, here we assume it succeeded correctly.
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
      contact: '9999999999', // Dummy contact
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

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: StreamBuilder<QuerySnapshot>(
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
    );
  }
}

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: const Center(child: Text('User Profile Settings')),
    );
  }
}
