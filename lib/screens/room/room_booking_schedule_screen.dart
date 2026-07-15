import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/room.dart';
import '../../services/booking_service.dart';
import '../../utils/app_colors.dart';

List<Booking> bookingsForRoom(List<Booking> bookings, int roomId) {
  final result = bookings.where((booking) {
    final status = booking.status.toLowerCase();
    final cancelled = status == 'cancelled' || status == 'canceled';
    return !cancelled && booking.roomIds.contains(roomId);
  }).toList();

  result.sort((a, b) => a.checkIn.compareTo(b.checkIn));
  return result;
}

class RoomBookingScheduleScreen extends StatefulWidget {
  final Room room;
  final Future<List<Booking>> Function()? loadBookings;

  const RoomBookingScheduleScreen({
    super.key,
    required this.room,
    this.loadBookings,
  });

  @override
  State<RoomBookingScheduleScreen> createState() =>
      _RoomBookingScheduleScreenState();
}

class _RoomBookingScheduleScreenState extends State<RoomBookingScheduleScreen> {
  late Future<List<Booking>> bookingFuture;

  @override
  void initState() {
    super.initState();
    bookingFuture = loadSchedule();
  }

  Future<List<Booking>> loadSchedule() async {
    final bookings =
        await (widget.loadBookings ?? BookingService.getBookings)();
    return bookingsForRoom(bookings, widget.room.roomId);
  }

  void refreshData() {
    setState(() => bookingFuture = loadSchedule());
  }

  DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String shortDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value.isEmpty ? 'Chưa rõ' : value;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String stayState(Booking booking) {
    final checkIn = DateTime.tryParse(booking.checkIn);
    final checkOut = DateTime.tryParse(booking.checkOut);
    if (checkIn == null || checkOut == null) return 'Chưa rõ';

    final today = dateOnly(DateTime.now());
    final start = dateOnly(checkIn);
    final end = dateOnly(checkOut);
    if (!today.isBefore(start) && today.isBefore(end)) return 'Đang lưu trú';
    if (today.isBefore(start)) return 'Sắp tới';
    return 'Đã kết thúc';
  }

  Color stayColor(String state) {
    switch (state) {
      case 'Đang lưu trú':
        return Colors.green;
      case 'Sắp tới':
        return AppColors.gold;
      default:
        return AppColors.textGray;
    }
  }

  Widget overview(List<Booking> bookings) {
    final current = bookings
        .where((booking) => stayState(booking) == 'Đang lưu trú')
        .length;
    final upcoming = bookings
        .where((booking) => stayState(booking) == 'Sắp tới')
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF2B3E6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phòng ${widget.room.roomNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.room.roomTypeName.isEmpty
                ? 'Loại phòng #${widget.room.roomTypeId}'
                : widget.room.roomTypeName,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              overviewValue('${bookings.length}', 'Tổng lịch'),
              overviewValue('$current', 'Đang ở'),
              overviewValue('$upcoming', 'Sắp tới'),
            ],
          ),
        ],
      ),
    );
  }

  Widget overviewValue(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget bookingCard(Booking booking, bool last) {
    final state = stayState(booking);
    final color = stayColor(state);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 132,
                  color: AppColors.gold.withValues(alpha: 0.24),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withValues(alpha: 0.25)),
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
                    Expanded(
                      child: Text(
                        'Booking #${booking.bookingId}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        state,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      color: Colors.green,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check-in: ${shortDate(booking.checkIn)}',
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check-out: ${shortDate(booking.checkOut)}',
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  booking.username.isEmpty
                      ? '${booking.totalGuests} khách'
                      : '${booking.username} • ${booking.totalGuests} khách',
                  style: const TextStyle(color: AppColors.textGray),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget schedule(List<Booking> bookings) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        overview(bookings),
        const SizedBox(height: 22),
        const Text(
          'Lịch đặt phòng',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: Colors.green,
                  size: 42,
                ),
                SizedBox(height: 10),
                Text(
                  'Phòng chưa có lịch đặt',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            bookings.length,
            (index) =>
                bookingCard(bookings[index], index == bookings.length - 1),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: const Text('Lịch đặt phòng'),
        actions: [
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
        future: bookingFuture,
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
                  'Không thể tải lịch đặt: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDark),
                ),
              ),
            );
          }
          return schedule(snapshot.data ?? const []);
        },
      ),
    );
  }
}
