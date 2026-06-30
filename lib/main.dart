import 'package:flutter/material.dart';
import 'screens/staff/staff_home_screen.dart';

void main() {
  runApp(const HotelStaffApp());
}

class HotelStaffApp extends StatelessWidget {
  const HotelStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAISON Hotel Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF16233D),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC2A04C),
        ),
      ),
      home: const StaffHomeScreen(),
    );
  }
}
