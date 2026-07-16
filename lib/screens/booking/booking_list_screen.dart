import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/customer.dart';
import '../../models/promotion.dart';
import '../../services/booking_service.dart';
import '../../services/customer_service.dart';
import '../../services/promotion_service.dart';
import '../../utils/app_colors.dart';
import '../widgets/list_query_bar.dart';
import 'add_booking_screen.dart';
import 'booking_detail_screen.dart';
import 'edit_booking_screen.dart';

bool isCurrentHotelBooking(Booking booking, DateTime now) {
  final checkIn = DateTime.tryParse(booking.checkIn);
  final checkOut = DateTime.tryParse(booking.checkOut);
  if (checkIn == null || checkOut == null) return false;

  final status = booking.status.toLowerCase();
  if (const {'cancelled', 'canceled', 'completed', 'done'}.contains(status)) {
    return false;
  }

  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(checkIn.year, checkIn.month, checkIn.day);
  final end = DateTime(checkOut.year, checkOut.month, checkOut.day);
  return !today.isBefore(start) && today.isBefore(end);
}

class BookingAdminData {
  final List<Booking> bookings;
  final Map<int, String> customerNames;
  final Map<int, double> promotionDiscounts;

  const BookingAdminData({
    required this.bookings,
    required this.customerNames,
    required this.promotionDiscounts,
  });
}

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  late Future<BookingAdminData> bookingFuture;
  String searchQuery = '';
  String sortBy = 'newest';
  String filterBy = 'all';
  bool currentOnly = false;

  @override
  void initState() {
    super.initState();
    bookingFuture = loadData();
  }

  void refreshData() {
    setState(() {
      bookingFuture = loadData();
    });
  }

  Future<BookingAdminData> loadData() async {
    final bookings = await BookingService.getBookings();
    final customersFuture = CustomerService.getCustomers().catchError(
      (_) => <Customer>[],
    );
    final promotionsFuture = PromotionService.getPromotions().catchError(
      (_) => <Promotion>[],
    );
    final customers = await customersFuture;
    final promotions = await promotionsFuture;

    return BookingAdminData(
      bookings: bookings,
      customerNames: {
        for (final customer in customers)
          customer.userId: [
            customer.firstName.trim(),
            customer.lastName.trim(),
          ].where((part) => part.isNotEmpty).join(' '),
      },
      promotionDiscounts: {
        for (final promotion in promotions)
          promotion.promotionId: promotion.discountValue,
      },
    );
  }

  String customerName(Booking booking, BookingAdminData data) {
    final name = data.customerNames[booking.userId]?.trim() ?? '';
    return name.isEmpty ? 'Khách hàng #${booking.userId}' : name;
  }

  String discountLabel(Booking booking, BookingAdminData data) {
    if (booking.promotionId == null) return '';
    final discount = data.promotionDiscounts[booking.promotionId];
    if (discount == null) return 'Mã #${booking.promotionId}';
    final value = discount == discount.roundToDouble()
        ? discount.toStringAsFixed(0)
        : discount.toStringAsFixed(1);
    return 'Giảm $value%';
  }

  List<Booking> applyQuery(BookingAdminData data) {
    final bookings = data.bookings;
    final query = searchQuery.trim().toLowerCase();
    final now = DateTime.now();
    final result = bookings.where((booking) {
      final matchesSearch =
          query.isEmpty ||
          booking.bookingId.toString().contains(query) ||
          customerName(booking, data).toLowerCase().contains(query) ||
          booking.userId.toString().contains(query) ||
          booking.roomNumbers.any(
            (number) => number.toLowerCase().contains(query),
          ) ||
          booking.roomIds.any((id) => id.toString().contains(query));
      final matchesStatus =
          filterBy == 'all' || booking.status.toLowerCase() == filterBy;
      final matchesCurrent =
          !currentOnly || isCurrentHotelBooking(booking, now);
      return matchesSearch && matchesStatus && matchesCurrent;
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'check_in') return a.checkIn.compareTo(b.checkIn);
      if (sortBy == 'check_out') return a.checkOut.compareTo(b.checkOut);
      if (sortBy == 'price') {
        return (b.totalPrice ?? 0).compareTo(a.totalPrice ?? 0);
      }
      return b.bookingId.compareTo(a.bookingId);
    });
    return result;
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

  Future<void> goToEdit(Booking booking, String customerName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditBookingScreen(booking: booking, customerName: customerName),
      ),
    );
    refreshData();
  }

  void openDetails(Booking booking, BookingAdminData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          booking: booking,
          customerName: customerName(booking, data),
          promotionDiscount: data.promotionDiscounts[booking.promotionId],
        ),
      ),
    );
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
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
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

  Widget bookingOverview(List<Booking> bookings) {
    final current = bookings
        .where((booking) => isCurrentHotelBooking(booking, DateTime.now()))
        .toList();
    final guestCount = current.fold<int>(
      0,
      (total, booking) => total + booking.totalGuests,
    );
    final roomCount = current
        .expand((booking) => booking.roomNumbers)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF293B68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hotel_rounded, color: AppColors.gold),
              SizedBox(width: 10),
              Text(
                'Khách đang lưu trú',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              overviewValue('${current.length}', 'booking'),
              overviewValue('$guestCount', 'khách'),
              overviewValue('$roomCount', 'phòng'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: viewButton(
                  label: 'Tất cả',
                  selected: !currentOnly,
                  onTap: () => setState(() => currentOnly = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: viewButton(
                  label: 'Đang lưu trú',
                  selected: currentOnly,
                  onTap: () => setState(() => currentOnly = true),
                ),
              ),
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
              color: AppColors.gold,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget viewButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.navy : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget bookingCard(Booking booking, BookingAdminData data) {
    final current = isCurrentHotelBooking(booking, DateTime.now());
    final name = customerName(booking, data);
    final promotion = discountLabel(booking, data);

    return InkWell(
      key: ValueKey('booking-${booking.bookingId}'),
      onTap: () => openDetails(booking, data),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: current
              ? Border.all(color: AppColors.gold, width: 1.5)
              : null,
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
              backgroundColor: (current ? Colors.green : AppColors.gold)
                  .withValues(alpha: 0.18),
              child: Icon(
                current ? Icons.hotel_rounded : Icons.calendar_month_rounded,
                color: current ? Colors.green : AppColors.gold,
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
                    name,
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
                  if (booking.roomNumbers.isNotEmpty)
                    Text(
                      'Phòng: ${booking.roomNumbers.join(', ')}',
                      style: const TextStyle(color: AppColors.textGray),
                    ),
                  if (booking.totalPrice != null)
                    Text(
                      '${booking.totalPrice!.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    'Trạng thái: ${booking.status}',
                    style: TextStyle(
                      color: statusColor(booking.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (promotion.isNotEmpty)
                    Text(
                      promotion,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            Column(
              children: [
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGray,
                ),
                IconButton(
                  onPressed: () => goToEdit(booking, name),
                  icon: const Icon(Icons.edit_rounded, color: AppColors.gold),
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
        child: const Icon(Icons.add, color: AppColors.navy),
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
                    icon: const Icon(Icons.arrow_back, color: AppColors.gold),
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
                    icon: const Icon(Icons.refresh, color: AppColors.gold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<BookingAdminData>(
                future: bookingFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  final data =
                      snapshot.data ??
                      const BookingAdminData(
                        bookings: [],
                        customerNames: {},
                        promotionDiscounts: {},
                      );
                  final allBookings = data.bookings;
                  final bookings = applyQuery(data);

                  if (allBookings.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không có booking',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      bookingOverview(allBookings),
                      const SizedBox(height: 16),
                      ListQueryBar(
                        searchHint: 'Tìm booking, khách, phòng...',
                        onSearchChanged: (value) =>
                            setState(() => searchQuery = value),
                        sortValue: sortBy,
                        sortOptions: const {
                          'newest': 'Booking mới nhất',
                          'check_in': 'Check-in gần nhất',
                          'check_out': 'Check-out gần nhất',
                          'price': 'Giá trị cao nhất',
                        },
                        onSortChanged: (value) =>
                            setState(() => sortBy = value ?? 'newest'),
                        filterValue: filterBy,
                        filterOptions: const {
                          'all': 'Tất cả trạng thái',
                          'pending': 'Chờ xác nhận',
                          'confirmed': 'Đã xác nhận',
                          'completed': 'Hoàn tất',
                          'cancelled': 'Đã hủy',
                        },
                        onFilterChanged: (value) =>
                            setState(() => filterBy = value ?? 'all'),
                        resultCount: bookings.length,
                      ),
                      const SizedBox(height: 16),
                      if (bookings.isEmpty)
                        Center(
                          child: Text(
                            currentOnly
                                ? 'Hiện không có khách đang lưu trú'
                                : 'Không có booking phù hợp',
                          ),
                        )
                      else
                        ...bookings.map(
                          (booking) => bookingCard(booking, data),
                        ),
                    ],
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
