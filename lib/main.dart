import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Services
import 'services/notification_service.dart';

// ViewModels
import 'view_models/auth_view_model.dart';
import 'view_models/map_view_model.dart';
import 'view_models/request_view_model.dart';
import 'view_models/chat_view_model.dart';

// Views
import 'package:quick_hub_project/view/screens/login_screen.dart';


import 'core/theme.dart';

void main() async {
  // Ensure widget bindings are initialized before Firebase Core
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the newly generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Cloud Messaging (FCM)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Run the app wrapped in our State Providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(create: (_) => RequestViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Dynamically swaps based on device setting
      // We use AuthenticationWrapper instead of hardcoded LoginScreen
      // to automatically respond to login state changes.
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch listens to state changes in AuthViewModel real-time
    final authViewModel = context.watch<AuthViewModel>();
    
    // Auth Routing Logic
    if (authViewModel.currentUser != null) {
      final user = authViewModel.currentUser!;
      
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome back, ${user.name}!"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.read<AuthViewModel>().logout(), 
                child: const Text('Logout')
              )
            ],
          ),
        )
      );
      // In the next step, we will route directly to HomeMapScreen (Consumer) 
      // or ProviderDashboardScreen (Provider) here instead of this placeholder text.
    }
    
    // If no user is logged in, show Login Screen.
    return LoginScreen(); // Remove 'const' if your screen isn't const
  }
}
