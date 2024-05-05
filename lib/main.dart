import 'package:flutter/material.dart';
import 'package:test_2/homeScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SMS Test',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}