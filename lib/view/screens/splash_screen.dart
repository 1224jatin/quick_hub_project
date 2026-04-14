import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quick_hub_project/main.dart';
import '../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Hold the splash screen for 3 seconds to let the Lottie play completely
    await Future.delayed(const Duration(milliseconds: 3200));
    
    if (mounted) {
      // Transition smoothly to the AuthenticationWrapper
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const AuthenticationWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Uses the dynamic AppTheme we configured earlier (Defaults to Navy)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.primaryDarkBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Lottie.asset(
          'lib/assets/animations/help.json',
          width: 350,
          height: 350,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Reverts to an elegant icon if the json file isn't fully placed yet
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handyman, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Quick Hub",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
