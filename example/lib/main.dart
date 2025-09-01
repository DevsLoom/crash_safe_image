import 'package:flutter/material.dart';
import 'package:crash_safe_image/crash_safe_image.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('CrashSafeImage Demo')),
        body: Center(
          child: CrashSafeImage(
            'https://cdn4.iconfinder.com/data/icons/flat-brand-logo-2/512/visa-512.png',
            width: 80,
            height: 50,
          ),
        ),
      ),
    );
  }
}
