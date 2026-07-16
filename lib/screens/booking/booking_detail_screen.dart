import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../utils/app_colors.dart';

class BookingDetailScreen extends StatelessWidget {
  final Booking booking;
  final String customerName;
  final double? promotionDiscount;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.customerName,
    this.promotionDiscount,
  });

  String money(double? value) {
    if (value == null) return 'Chưa có';
    final raw = value.round().toString();
    final formatted = raw.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '$formatted VNĐ';
  }

  String dateTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value.isEmpty ? 'Chưa có' : value;
    final date = parsed.isUtc ? parsed.toLocal() : parsed;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  int stayNights() {
    if (booking.numberOfNights != null) return booking.numberOfNights!;
    final checkIn = DateTime.tryParse(booking.checkIn);
    final checkOut = DateTime.tryParse(booking.checkOut);
    if (checkIn == null || checkOut == null) return 0;
    return checkOut.difference(checkIn).inDays;
  }

  String statusLabel() {
    switch (booking.status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      default:
        return booking.status.isEmpty ? 'Chưa rõ' : booking.status;
    }
  }

  Color statusColor() {
    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'canceled':
        return Colors.redAccent;
      default:
        return AppColors.gold;
    }
  }

  String promotionLabel() {
    if (booking.promotionId == null) return 'Không sử dụng';
    if (promotionDiscount == null) return 'Mã #${booking.promotionId}';
    final value = promotionDiscount == promotionDiscount!.roundToDouble()
        ? promotionDiscount!.toStringAsFixed(0)
        : promotionDiscount!.toStringAsFixed(1);
    return 'Giảm $value% (Mã #${booking.promotionId})';
  }

  Widget section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget roomChips() {
    if (booking.roomNumbers.isEmpty) {
      return const Text(
        'Chưa có số phòng',
        style: TextStyle(color: AppColors.textGray),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: booking.roomNumbers
          .map(
            (roomNumber) => Chip(
              avatar: const Icon(
                Icons.bed_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              label: Text('Phòng $roomNumber'),
              backgroundColor: AppColors.gold.withValues(alpha: 0.12),
              side: BorderSide.none,
              labelStyle: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text('Booking #${booking.bookingId}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, Color(0xFF2A3C69)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.luggage_rounded,
                      color: AppColors.gold,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    money(booking.totalPrice),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel(),
                      style: TextStyle(
                        color: color == AppColors.gold
                            ? AppColors.gold
                            : color == Colors.green
                            ? Colors.greenAccent
                            : color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            section(
              title: 'Thông tin khách hàng',
              icon: Icons.person_rounded,
              children: [
                detailRow('User ID', '#${booking.userId}'),
                detailRow('Tên khách hàng', customerName),
                detailRow('Số khách', '${booking.totalGuests} khách'),
              ],
            ),
            section(
              title: 'Thời gian lưu trú',
              icon: Icons.date_range_rounded,
              children: [
                detailRow('Ngày tạo booking', dateTime(booking.bookingDate)),
                detailRow('Check-in', dateTime(booking.checkIn)),
                detailRow('Check-out', dateTime(booking.checkOut)),
                detailRow('Số đêm', '${stayNights()} đêm'),
                if (booking.numberOfDays != null)
                  detailRow('Số ngày', '${booking.numberOfDays} ngày'),
              ],
            ),
            section(
              title: 'Phòng đã đặt',
              icon: Icons.hotel_rounded,
              children: [roomChips()],
            ),
            section(
              title: 'Thanh toán và khuyến mãi',
              icon: Icons.payments_rounded,
              children: [
                detailRow('Tổng tiền', money(booking.totalPrice)),
                detailRow('Khuyến mãi', promotionLabel()),
                detailRow(
                  'Trạng thái',
                  statusLabel(),
                  valueColor: statusColor(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
