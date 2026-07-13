import 'package:flutter/material.dart';

import '../../../core/models/user_booking_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/colors.dart';
import '../../payment/controller/payment_controller.dart';
import '../../payment/services/invoice_pdf_service.dart';
import '../../payment/view/payment_qr_screen.dart';
import '../controller/bookings_controller.dart';

class MyBookingsScreen extends StatefulWidget {
  final UserModel user;

  const MyBookingsScreen({super.key, required this.user});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final bookingsController = BookingsController();
  final paymentController = PaymentController();
  final invoicePdfService = InvoicePdfService();
  late Future<List<UserBookingModel>> bookingsFuture;
  String selectedStatus = 'all';
  int? openingBookingId;
  int? downloadingInvoiceBookingId;

  @override
  void initState() {
    super.initState();
    bookingsFuture = fetchBookings();
  }

  Future<List<UserBookingModel>> fetchBookings() {
    final userId = int.tryParse(widget.user.userId);
    if (userId == null) throw Exception('Invalid user session');
    return bookingsController.fetchBookings(userId);
  }

  Future<void> refreshBookings() async {
    final future = fetchBookings();
    setState(() {
      bookingsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bookings')),
      body: FutureBuilder<List<UserBookingModel>>(
        future: bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _BookingsError(
              message: snapshot.error.toString(),
              onRetry: refreshBookings,
            );
          }

          final bookings = snapshot.data ?? const [];
          final filtered = selectedStatus == 'all'
              ? bookings
              : bookings
                    .where(
                      (booking) =>
                          booking.payment.status.toLowerCase() ==
                          selectedStatus,
                    )
                    .toList();

          return RefreshIndicator(
            onRefresh: refreshBookings,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _BookingStatusFilter(
                  selectedStatus: selectedStatus,
                  onChanged: (status) {
                    setState(() => selectedStatus = status);
                  },
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  const _EmptyBookings()
                else
                  ...filtered.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BookingCard(
                        booking: booking,
                        isOpening: openingBookingId == booking.bookingId,
                        isDownloadingInvoice:
                            downloadingInvoiceBookingId == booking.bookingId,
                        onTap: () => openBooking(booking),
                        onDownloadInvoice:
                            booking.payment.status.toLowerCase() == 'paid'
                            ? () => downloadInvoice(booking)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> downloadInvoice(UserBookingModel booking) async {
    if (downloadingInvoiceBookingId != null) return;
    setState(() => downloadingInvoiceBookingId = booking.bookingId);
    try {
      final path = await invoicePdfService.download(
        bookingId: booking.bookingId,
        room: booking.room,
        user: widget.user,
        checkIn: booking.checkIn,
        checkOut: booking.checkOut,
        guests: booking.totalGuests,
        nights: booking.numberOfNights,
      );
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice PDF saved')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => downloadingInvoiceBookingId = null);
    }
  }

  Future<void> openBooking(UserBookingModel booking) async {
    if (openingBookingId != null) return;
    setState(() => openingBookingId = booking.bookingId);

    try {
      final payment = await paymentController.getPayment(booking.bookingId);
      if (!mounted) return;

      final checkIn = booking.checkIn;
      final checkOut = booking.checkOut;
      final stayRange = checkIn != null && checkOut != null
          ? DateTimeRange(start: checkIn, end: checkOut)
          : null;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentQrScreen(
            room: booking.room,
            user: widget.user,
            roomTypeName: booking.room.roomTypeName,
            stayRange: stayRange,
            nights: booking.numberOfNights > 0
                ? booking.numberOfNights
                : stayRange?.duration.inDays ?? 1,
            guests: booking.totalGuests,
            payment: payment,
          ),
        ),
      );
      if (mounted) await refreshBookings();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => openingBookingId = null);
    }
  }
}

class _BookingStatusFilter extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const _BookingStatusFilter({
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'all', label: Text('All')),
          ButtonSegment(value: 'pending', label: Text('Pending')),
          ButtonSegment(value: 'paid', label: Text('Paid')),
        ],
        selected: {selectedStatus},
        onSelectionChanged: (selection) => onChanged(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final UserBookingModel booking;
  final bool isOpening;
  final bool isDownloadingInvoice;
  final VoidCallback onTap;
  final VoidCallback? onDownloadInvoice;

  const _BookingCard({
    required this.booking,
    required this.isOpening,
    required this.isDownloadingInvoice,
    required this.onTap,
    required this.onDownloadInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = booking.payment.status.toLowerCase() == 'paid';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    return InkWell(
      onTap: isOpening ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.hotel_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${booking.room.roomNumber}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${booking.room.roomTypeName} · Booking #${booking.bookingId}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _PaymentStatusBadge(
                  label: isPaid ? 'Paid' : 'Pending',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BookingInfo(
              icon: Icons.calendar_today_outlined,
              text: _stayText(booking),
            ),
            const SizedBox(height: 8),
            _BookingInfo(
              icon: Icons.people_outline,
              text:
                  '${booking.totalGuests} guest${booking.totalGuests == 1 ? '' : 's'} · '
                  '${booking.numberOfNights} night${booking.numberOfNights == 1 ? '' : 's'}',
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_formatAmount(booking.payment.amount)} VND',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isDownloadingInvoice)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (onDownloadInvoice != null)
                  IconButton(
                    onPressed: onDownloadInvoice,
                    tooltip: 'Download invoice PDF',
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                if (isOpening)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  Text(
                    isPaid ? 'View payment' : 'Continue payment',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BookingInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PaymentStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: const [
          Icon(Icons.calendar_month_outlined, size: 54, color: AppColors.hint),
          SizedBox(height: 14),
          Text(
            'No bookings found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Your pending and paid bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _BookingsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _stayText(UserBookingModel booking) {
  if (booking.checkIn == null || booking.checkOut == null) {
    return 'Stay dates unavailable';
  }
  return '${_formatDate(booking.checkIn!)} - ${_formatDate(booking.checkOut!)}';
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatAmount(int amount) {
  return amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}
