import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    // Wait 2 seconds, then open LoginScreen
    Timer(
      const Duration(seconds: 2),
      () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // QR icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 70,
                color: Color(0xFF175CD3),
              ),
            ),

            const SizedBox(height: 30),

            // App title
            const Text(
              'QR ATTENDANCE',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123A91),
              ),
            ),

            const Text(
              'SYSTEM',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123A91),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Smart • Simple • Secure',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF151A2D),
              ),
            ),

            const SizedBox(height: 40),

            // Loading indicator
            const SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF175CD3),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Loading...',
              style: TextStyle(
                color: Color(0xFF175CD3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}