import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../utils/app_colors.dart';
import 'add_booking_screen.dart';
import 'edit_booking_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  late Future<List<Booking>> bookingFuture;

  @override
  void initState() {
    super.initState();
    bookingFuture = BookingService.getBookings();
  }

  void refreshData() {
    setState(() {
      bookingFuture = BookingService.getBookings();
    });
  }

  String shortDate(String value) {
    if (value.isEmpty) return '';
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  Future<void> goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddBookingScreen()),
    );
    refreshData();
  }

  Future<void> goToEdit(Booking booking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBookingScreen(booking: booking),
      ),
    );
    refreshData();
  }

  Future<void> confirmDelete(Booking booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa booking #${booking.bookingId} không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await BookingService.deleteBooking(booking.bookingId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Xóa booking thành công' : 'Xóa booking thất bại',
          ),
        ),
      );

      if (success) refreshData();
    }
  }

  Color statusColor(String status) {
    if (status == 'confirmed') return Colors.green;
    if (status == 'completed') return Colors.blue;
    if (status == 'cancelled') return Colors.redAccent;
    return AppColors.gold;
  }

  Widget bookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.gold.withOpacity(0.18),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking #${booking.bookingId}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  booking.username.isEmpty
                      ? 'User ID: ${booking.userId}'
                      : booking.username,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check-in: ${shortDate(booking.checkIn)}',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  'Check-out: ${shortDate(booking.checkOut)}',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  'Khách: ${booking.totalGuests}',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                Text(
                  'Trạng thái: ${booking.status}',
                  style: TextStyle(
                    color: statusColor(booking.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                onPressed: () => goToEdit(booking),
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.gold,
                ),
              ),
              IconButton(
                onPressed: () => confirmDelete(booking),
                icon: const Icon(
                  Icons.delete_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: goToAdd,
        child: const Icon(
          Icons.add,
          color: AppColors.navy,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.gold,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Quản lý booking',
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
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<List<Booking>>(
                future: bookingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(
                          color: AppColors.textDark,
                        ),
                      ),
                    );
                  }

                  final bookings = snapshot.data ?? [];

                  if (bookings.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có booking',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return bookingCard(bookings[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}