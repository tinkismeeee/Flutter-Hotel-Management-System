import 'package:flutter/material.dart';
import 'screens/admin/admin_screen.dart';

void main() {
  runApp(const HotelAdminApp());
}

class HotelAdminApp extends StatelessWidget {
  const HotelAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAISON Hotel Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF16233D),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC2A04C),
        ),
      ),
      home: const AdminScreen(),
    );
  }
}