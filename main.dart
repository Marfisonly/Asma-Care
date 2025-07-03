import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AsmaApp());
}

class AsmaApp extends StatelessWidget {
  const AsmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AsmaCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.transparent, // transparan agar gradient terlihat
      ),
      home: const GradientWrapper(child: SplashScreen()),
    );
  }
}

/// Widget pembungkus yang memberi latar belakang gradien
class GradientWrapper extends StatelessWidget {
  final Widget child;

  const GradientWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2196F3), // biru
            Colors.white,      // putih
          ],
        ),
      ),
      child: child,
    );
  }
}
