import 'package:flutter/material.dart';

import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';

class PaymentQrScreen extends StatelessWidget {
  static const qrUrl = 'https://img.vietqr.io/image/TCB-2707200505-compact.png';

  final RoomModel room;
  final UserModel user;

  const PaymentQrScreen({super.key, required this.room, required this.user});

  @override
  Widget build(BuildContext context) {
    final payerName = _payerName(user);
    final transferContent = 'ROOM-${room.roomNumber}-${user.username}';

    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        foregroundColor: const Color(0xFF171725),
        elevation: 0,
        title: const Text(
          'Payment',
          style: TextStyle(fontFamily: 'Jost', fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room ${room.roomNumber}',
                    style: const TextStyle(
                      color: Color(0xFF171725),
                      fontSize: 20,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room.roomTypeName,
                    style: const TextStyle(
                      color: Color(0xFF78828A),
                      fontSize: 14,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_formatPrice(room.pricePerNight)} VND',
                    style: const TextStyle(
                      color: Color(0xFF2852AF),
                      fontSize: 22,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qrUrl,
                  width: 260,
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _QrPlaceholder();
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PaymentInfo(label: 'Bank', value: 'Techcombank'),
            _PaymentInfo(label: 'Account', value: '2707200505'),
            _PaymentInfo(label: 'Name', value: payerName),
            _PaymentInfo(label: 'Content', value: transferContent),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment confirmation sent')),
                  );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2852AF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I have paid',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _payerName(UserModel user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (user.username.isNotEmpty) return user.username;
    return user.email;
  }
}

class _PaymentInfo extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF78828A),
                fontSize: 14,
                fontFamily: 'Jost',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF171725),
                fontSize: 14,
                fontFamily: 'Jost',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      color: const Color(0xFFE8EAEC),
      alignment: Alignment.center,
      child: const Icon(Icons.qr_code_2, size: 72),
    );
  }
}

String _formatPrice(String value) {
  final number = double.tryParse(value) ?? 0;
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}
