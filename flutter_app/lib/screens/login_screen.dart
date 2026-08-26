import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController studentIdController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // Blue header
              Container(
                height: 170,

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1558D6),
                      Color(0xFF2872E8),
                    ],
                  ),

                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(45),
                    bottomRight: Radius.circular(45),
                  ),
                ),

                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: const Icon(
                      Icons.school,
                      size: 50,
                      color: Color(0xFF151A2D),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Student Login',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Sign in to continue',
                style: TextStyle(
                  color: Color(0xFF667085),
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [

                    // Student ID
                    TextField(
                      controller: studentIdController,

                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),

                        hintText: 'Student ID',

                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Password
                    TextField(
                      controller: passwordController,

                      obscureText: obscurePassword,

                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),

                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),

                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },
                        ),

                        hintText: 'Password',

                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,

                      child: TextButton(
                        onPressed: () {},

                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF175CD3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: ElevatedButton(
                        onPressed: () {

                          Navigator.pushReplacement(
                            context,

                            MaterialPageRoute(
                              builder: (context) =>
                                  const DashboardScreen(),
                            ),
                          );

                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF175CD3),

                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                          ),
                        ),

                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 15),

                          child: Text('OR'),
                        ),

                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Don't have an account? Contact Admin",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}