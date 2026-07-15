import 'package:flutter/material.dart';

import '../../models/room.dart';
import '../../utils/app_colors.dart';
import '../room/room_booking_schedule_screen.dart';

class RoomDetailScreen extends StatelessWidget {
  final Room room;

  const RoomDetailScreen({super.key, required this.room});

  String money(double value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
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

  Widget header(BuildContext context) {
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
          Expanded(
            child: Text(
              'Phòng ${room.roomNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget summaryCard() {
    final typeName = room.roomTypeName.isEmpty
        ? 'Loại phòng ID: ${room.roomTypeId}'
        : room.roomTypeName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.meeting_room_rounded,
              color: AppColors.gold,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${money(room.pricePerNight)} VNĐ / đêm',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget detailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gold.withValues(alpha: 0.16),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void openBookingSchedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomBookingScheduleScreen(room: room)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  summaryCard(),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    key: const Key('roomBookingScheduleButton'),
                    onPressed: () => openBookingSchedule(context),
                    icon: const Icon(Icons.event_note_rounded),
                    label: const Text('Xem lịch đặt phòng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  detailItem(
                    icon: Icons.stairs_rounded,
                    title: 'Tầng',
                    value: room.floor.toString(),
                  ),
                  const SizedBox(height: 12),
                  detailItem(
                    icon: Icons.people_alt_rounded,
                    title: 'Sức chứa',
                    value: '${room.maxGuests} khách',
                  ),
                  const SizedBox(height: 12),
                  detailItem(
                    icon: Icons.bed_rounded,
                    title: 'Số giường',
                    value: '${room.bedCount} giường',
                  ),
                  const SizedBox(height: 12),
                  detailItem(
                    icon: Icons.verified_rounded,
                    title: 'Trạng thái',
                    value: statusLabel(room.status),
                    valueColor: statusColor(room.status),
                  ),
                  const SizedBox(height: 12),
                  detailItem(
                    icon: Icons.power_settings_new_rounded,
                    title: 'Hoạt động',
                    value: room.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
                    valueColor: room.isActive ? Colors.green : Colors.redAccent,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mô tả',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          room.description.isEmpty
                              ? 'Chưa có mô tả'
                              : room.description,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
