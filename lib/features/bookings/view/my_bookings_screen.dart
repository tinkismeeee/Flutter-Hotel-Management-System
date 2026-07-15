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
  final int refreshToken;
  final VoidCallback? onBackToHome;

  const MyBookingsScreen({
    super.key,
    required this.user,
    this.refreshToken = 0,
    this.onBackToHome,
  });

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final bookingsController = BookingsController();
  final paymentController = PaymentController();
  final invoicePdfService = InvoicePdfService();
  final searchController = TextEditingController();
  late Future<List<UserBookingModel>> bookingsFuture;
  String selectedTab = 'booked';
  String searchQuery = '';
  int? openingBookingId;
  int? downloadingInvoiceBookingId;

  @override
  void initState() {
    super.initState();
    bookingsFuture = fetchBookings();
  }

  @override
  void didUpdateWidget(covariant MyBookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) refreshBookings().ignore();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<UserBookingModel>> fetchBookings() {
    final userId = int.tryParse(widget.user.userId);
    if (userId == null) {
      return Future.error(Exception('Invalid user session'));
    }
    return bookingsController.fetchBookings(userId);
  }

  Future<void> refreshBookings() async {
    if (!mounted) return;
    final future = fetchBookings();
    setState(() {
      bookingsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _BookingHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _BookingSearch(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _BookingTabs(
                selectedTab: selectedTab,
                onChanged: (tab) {
                  setState(() {
                    selectedTab = tab;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<UserBookingModel>>(
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

                  final bookings = filterBookings(snapshot.data ?? const []);
                  return RefreshIndicator(
                    onRefresh: refreshBookings,
                    child: bookings.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children: [
                              _EmptyBookings(
                                hasSearch: searchQuery.isNotEmpty,
                                isHistory: selectedTab == 'history',
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                            itemCount: bookings.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              final isHistory = isHistoryBooking(booking);
                              return _BookingCard(
                                booking: booking,
                                isHistory: isHistory,
                                isOpening:
                                    openingBookingId == booking.bookingId,
                                isDownloadingInvoice:
                                    downloadingInvoiceBookingId ==
                                    booking.bookingId,
                                onTap: () => openBooking(booking),
                                onDownloadInvoice:
                                    isHistory &&
                                        booking.payment.status.toLowerCase() ==
                                            'paid'
                                    ? () => downloadInvoice(booking)
                                    : null,
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<UserBookingModel> filterBookings(List<UserBookingModel> bookings) {
    final filtered = bookings.where((booking) {
      final inHistory = isHistoryBooking(booking);
      if (selectedTab == 'history' ? !inHistory : inHistory) return false;
      if (searchQuery.isEmpty) return true;

      final searchable = [
        booking.bookingId.toString(),
        booking.room.roomNumber,
        booking.room.roomTypeName,
        booking.bookingStatus,
        booking.payment.status,
      ].join(' ').toLowerCase();
      return searchable.contains(searchQuery);
    }).toList();

    filtered.sort((first, second) {
      final firstDate = first.checkIn ?? first.bookingDate ?? DateTime(1970);
      final secondDate = second.checkIn ?? second.bookingDate ?? DateTime(1970);
      return selectedTab == 'history'
          ? secondDate.compareTo(firstDate)
          : firstDate.compareTo(secondDate);
    });
    return filtered;
  }

  bool isHistoryBooking(UserBookingModel booking) {
    final status = booking.bookingStatus.toLowerCase();
    final paymentStatus = booking.payment.status.toLowerCase();
    if ({
      'cancelled',
      'completed',
      'checked_out',
      'payment_conflict',
    }.contains(status)) {
      return true;
    }
    if (paymentStatus == 'cancelled' || paymentStatus == 'expired') return true;

    final checkOut = booking.checkOut;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return checkOut != null && checkOut.isBefore(today);
  }

  Future<void> downloadInvoice(UserBookingModel booking) async {
    if (downloadingInvoiceBookingId != null) return;
    setState(() {
      downloadingInvoiceBookingId = booking.bookingId;
    });
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
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          downloadingInvoiceBookingId = null;
        });
      }
    }
  }

  Future<void> openBooking(UserBookingModel booking) async {
    if (openingBookingId != null) return;
    setState(() {
      openingBookingId = booking.bookingId;
    });

    try {
      final payment = await paymentController.getPayment(booking.bookingId);
      if (!mounted) return;
      final stayRange = booking.checkIn != null && booking.checkOut != null
          ? DateTimeRange(start: booking.checkIn!, end: booking.checkOut!)
          : null;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentQrScreen(
            room: booking.room,
            user: widget.user,
            roomTypeName: booking.room.roomTypeName,
            stayRange: stayRange,
            nights: booking.numberOfNights > 0
                ? booking.numberOfNights
                : stayRange?.duration.inDays ?? 1,
            guests: booking.totalGuests,
            payment: payment,
            onBackToHome: widget.onBackToHome,
          ),
        ),
      );
      if (mounted) await refreshBookings();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          openingBookingId = null;
        });
      }
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(width: 68),
          Expanded(
            child: Text(
              'My Booking',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontFamily: 'Jost',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.09,
              ),
            ),
          ),
          SizedBox(width: 68),
        ],
      ),
    );
  }
}

class _BookingSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BookingSearch({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontFamily: 'Jost',
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: const TextStyle(
            color: AppColors.hint,
            fontSize: 14,
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.07,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: const Icon(Icons.tune_rounded, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _BookingTabs extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onChanged;

  const _BookingTabs({required this.selectedTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _BookingTab(
            label: 'Booked',
            selected: selectedTab == 'booked',
            onTap: () => onChanged('booked'),
          ),
          _BookingTab(
            label: 'History',
            selected: selectedTab == 'history',
            onTap: () => onChanged('history'),
          ),
        ],
      ),
    );
  }
}

class _BookingTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BookingTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFA7A9B7).withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.hint,
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final UserBookingModel booking;
  final bool isHistory;
  final bool isOpening;
  final bool isDownloadingInvoice;
  final VoidCallback onTap;
  final VoidCallback? onDownloadInvoice;

  const _BookingCard({
    required this.booking,
    required this.isHistory,
    required this.isOpening,
    required this.isDownloadingInvoice,
    required this.onTap,
    required this.onDownloadInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final roomType = booking.room.roomTypeName.trim();
    final pending = booking.payment.status.toLowerCase() == 'pending';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOpening ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 76,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bed_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          booking.room.roomNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Room ${booking.room.roomNumber}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isOpening)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.hint,
                              ),
                          ],
                        ),
                        if (roomType.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.hotel_outlined,
                                size: 16,
                                color: AppColors.hint,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  roomType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.hint,
                                    fontSize: 12,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${_formatPrice(booking.room.pricePerNight)} VND',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(
                                text: ' /night',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontFamily: 'Plus Jakarta Sans',
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
              const Divider(height: 25, color: AppColors.border),
              _BookingDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Dates',
                value: _stayText(booking),
              ),
              const SizedBox(height: 10),
              _BookingDetailRow(
                icon: Icons.people_outline_rounded,
                label: 'Guest',
                value:
                    '${booking.totalGuests} guest${booking.totalGuests == 1 ? '' : 's'} '
                    '(1 room)',
              ),
              if (isHistory && onDownloadInvoice != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isDownloadingInvoice ? null : onDownloadInvoice,
                    icon: isDownloadingInvoice
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Download invoice'),
                  ),
                ),
              ] else if (pending) ...[
                const SizedBox(height: 10),
                const Text(
                  'Tap to continue payment',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BookingDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textPrimary),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  final bool hasSearch;
  final bool isHistory;

  const _EmptyBookings({required this.hasSearch, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 54,
            color: AppColors.hint,
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch
                ? 'No matching bookings'
                : isHistory
                ? 'No booking history'
                : 'No booked rooms',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
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
    return 'Unavailable';
  }
  return '${_formatDate(booking.checkIn!)} - ${_formatDate(booking.checkOut!)}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatPrice(String value) {
  final amount = double.tryParse(value) ?? 0;
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
