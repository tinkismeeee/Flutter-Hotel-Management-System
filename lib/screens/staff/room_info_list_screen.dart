import 'package:flutter/material.dart';

import '../../models/room.dart';
import '../../services/room_service.dart';
import '../../utils/app_colors.dart';
import 'room_detail_screen.dart';

class RoomInfoListScreen extends StatefulWidget {
  const RoomInfoListScreen({super.key});

  @override
  State<RoomInfoListScreen> createState() => _RoomInfoListScreenState();
}

class _RoomInfoListScreenState extends State<RoomInfoListScreen> {
  late Future<List<Room>> roomFuture;

  @override
  void initState() {
    super.initState();
    roomFuture = RoomService.getRooms();
  }

  void refreshData() {
    setState(() {
      roomFuture = RoomService.getRooms();
    });
  }

  void openRoomDetail(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room)),
    );
  }

  String money(double value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }

  String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Còn trống';
      case 'booked':
        return 'Đã đặt';
      case 'occupied':
        return 'Đang ở';
      case 'maintenance':
        return 'Bảo trì';
      default:
        return status.isEmpty ? 'Chưa rõ' : status;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'booked':
      case 'occupied':
        return Colors.orange;
      case 'maintenance':
        return Colors.redAccent;
      default:
        return AppColors.textGray;
    }
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          ),
          const Expanded(
            child: Text(
              'Thông tin phòng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget roomCard(Room room) {
    final typeName = room.roomTypeName.isEmpty
        ? 'Loại phòng ID: ${room.roomTypeId}'
        : room.roomTypeName;

    return InkWell(
      onTap: () => openRoomDetail(room),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.gold.withValues(alpha: 0.18),
              child: const Icon(Icons.bed_rounded, color: AppColors.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng ${room.roomNumber}',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    typeName,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tầng ${room.floor} • ${room.maxGuests} khách • ${room.bedCount} giường',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                  Text(
                    '${money(room.pricePerNight)} VNĐ / đêm',
                    style: const TextStyle(color: AppColors.textGray),
                  ),
                  Text(
                    statusLabel(room.status),
                    style: TextStyle(
                      color: statusColor(room.status),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }

  Widget roomList(List<Room> rooms) {
    if (rooms.isEmpty) {
      return const Center(
        child: Text(
          'Không có phòng',
          style: TextStyle(color: AppColors.textDark),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rooms.length,
      itemBuilder: (context, index) => roomCard(rooms[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            header(),
            Expanded(
              child: FutureBuilder<List<Room>>(
                future: roomFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Lỗi: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                      ),
                    );
                  }

                  return roomList(snapshot.data ?? []);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
