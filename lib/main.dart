import 'package:flutter/material.dart';
import 'features/scanner/camera_scanner_screen.dart';

// Entry point of the Flutter application.
void main() {
  runApp(const DocScanApp());
}

/// Root widget of the application configured with Material 3 and a teal color scheme.
class DocScanApp extends StatelessWidget {
  const DocScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      // Sets the initial screen of the app to our camera scanner interface.
      home: const CameraScannerScreen(),
    );
  }
}