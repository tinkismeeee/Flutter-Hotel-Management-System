import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/const/api_endpoints.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/user_model.dart';
import '../../payment/view/payment_qr_screen.dart';

class DetailRoomScreen extends StatefulWidget {
  final int roomId;
  final String? imageUrl;
  final UserModel user;

  const DetailRoomScreen({
    super.key,
    required this.roomId,
    required this.user,
    this.imageUrl,
  });

  @override
  State<DetailRoomScreen> createState() => _DetailRoomScreenState();
}

class _DetailRoomScreenState extends State<DetailRoomScreen> {
  late Future<RoomModel> roomFuture;

  @override
  void initState() {
    super.initState();
    roomFuture = fetchRoomDetail();
  }

  Future<RoomModel> fetchRoomDetail() async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.room}/${widget.roomId}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch room: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body);
    final roomJson = switch (jsonData) {
      {'data': Map<String, dynamic> data} => data,
      Map<String, dynamic> data => data,
      _ => throw Exception('Invalid room detail response'),
    };

    return RoomModel.fromJson(roomJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        foregroundColor: const Color(0xFF171725),
        elevation: 0,
        title: const Text(
          'Room details',
          style: TextStyle(fontFamily: 'Jost', fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<RoomModel>(
        future: roomFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DetailError(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  roomFuture = fetchRoomDetail();
                });
              },
            );
          }

          return _DetailBody(
            room: snapshot.data!,
            imageUrl: widget.imageUrl,
            user: widget.user,
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final RoomModel room;
  final String? imageUrl;
  final UserModel user;

  const _DetailBody({
    required this.room,
    required this.imageUrl,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl == null
                  ? const _RoomImagePlaceholder()
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _RoomImagePlaceholder();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Room ${room.roomNumber}',
                  style: const TextStyle(
                    color: Color(0xFF171725),
                    fontSize: 24,
                    fontFamily: 'Jost',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(status: room.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            room.roomTypeName,
            style: const TextStyle(
              color: Color(0xFF78828A),
              fontSize: 15,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${_formatPrice(room.pricePerNight)} VND/night',
            style: const TextStyle(
              color: Color(0xFF2852AF),
              fontSize: 22,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _RoomFacts(room: room),
          const SizedBox(height: 28),
          const Text(
            'Description',
            style: TextStyle(
              color: Color(0xFF171725),
              fontSize: 18,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            room.description.isEmpty
                ? 'No description available.'
                : room.description,
            style: const TextStyle(
              color: Color(0xFF434E58),
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Jost',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: room.status == 'available'
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              PaymentQrScreen(room: room, user: user),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2852AF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE8EAEC),
                disabledForegroundColor: const Color(0xFF78828A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Book Now',
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
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EAEC),
      alignment: Alignment.center,
      child: const Icon(Icons.hotel, size: 40),
    );
  }
}

class _RoomFacts extends StatelessWidget {
  final RoomModel room;

  const _RoomFacts({required this.room});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _Fact(icon: Icons.layers_outlined, text: 'Floor ${room.floor}'),
        _Fact(icon: Icons.people_outline, text: '${room.maxGuests} guests'),
        _Fact(icon: Icons.bed_outlined, text: '${room.bedCount} beds'),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF78828A)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF78828A),
            fontSize: 13,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'available' => const Color(0xFF1A9C5B),
      'booked' => const Color(0xFFF59E0B),
      'maintenance' => const Color(0xFFF41F52),
      _ => const Color(0xFF78828A),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'Jost',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatPrice(String value) {
  final number = double.tryParse(value) ?? 0;
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}
