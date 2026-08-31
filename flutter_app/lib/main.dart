// Imports Flutter's Material Design widgets and classes
import 'package:flutter/material.dart';

// Imports our SplashScreen from the screens folder
import 'screens/splash_screen.dart';

// Entry point of the Dart/Flutter application
void main() {
  // Starts the Flutter application with QRAttendanceApp
  runApp(const QRAttendanceApp());
}

// Root widget of our application
class QRAttendanceApp extends StatelessWidget {

  // Constructor of QRAttendanceApp
  const QRAttendanceApp({super.key});

  // Builds the user interface
  @override
  Widget build(BuildContext context) {

    // Root widget that configures the application
    return MaterialApp(

      // Removes the DEBUG banner
      debugShowCheckedModeBanner: false,

      // Application title
      title: 'QR Attendance System',

      // Application's overall theme
      theme: ThemeData(
        // Enables Material 3 design
        useMaterial3: true,

        // Sets the default font
        fontFamily: 'Arial',
      ),

      // First screen displayed when the app starts
      home: const SplashScreen(),
    );
  }
}