import 'package:flutter/material.dart';

import '../../../core/models/room_model.dart';

class DetailRoomScreen extends StatelessWidget {
  final RoomModel room;
  final String? imageUrl;

  const DetailRoomScreen({super.key, required this.room, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFE),
        foregroundColor: const Color(0xFF171725),
        elevation: 0,
        title: Text(
          'Room ${room.roomNumber}',
          style: const TextStyle(
            fontFamily: 'Jost',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                onPressed: room.status == 'available' ? () {} : null,
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
