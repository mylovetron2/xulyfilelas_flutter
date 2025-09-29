import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const XuLyFileLasApp());
}

class XuLyFileLasApp extends StatelessWidget {
  const XuLyFileLasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xử Lý File LAS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}