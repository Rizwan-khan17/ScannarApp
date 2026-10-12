import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/scan_provider.dart'; // Provider import
import 'screens/home_screen.dart'; // First screen import

// ============================================================================
// FILE: lib/main.dart
// PURPOSE: Entry Point. Ye ScanProvider ko poori App tree me Inject karta hai,
// taaki har sub-screen is state ko easily manage/access kar sakay.
// ============================================================================

void main() {
  runApp(
    // MultiProvider app ke top level par lagaya gaya hai
    MultiProvider(
      providers: [
        // ScanProvider instance ko poori app me broadcast kar rahe hain
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: const CamScannerApp(),
    ),
  );
}

class CamScannerApp extends StatelessWidget {
  const CamScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamScanner Clone',
      debugShowCheckedModeBanner: false, // Debug badge remove kiya

      // CamScanner theme style matching
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212), // Pure Dark Background
        primaryColor: const Color(0xFF00BFA5), // CamScanner Green Color
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),

      // Application start hone par HomeScreen load hogi
      home: const HomeScreen(),
    );
  }
}