import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/models/booking.dart';
import 'package:hotel_system_management/models/invoice.dart';
import 'package:hotel_system_management/models/room.dart';
import 'package:hotel_system_management/screens/booking/booking_list_screen.dart';
import 'package:hotel_system_management/screens/booking/booking_detail_screen.dart';
import 'package:hotel_system_management/screens/revenue/invoice_detail_screen.dart';
import 'package:hotel_system_management/screens/room/room_booking_schedule_screen.dart';
import 'package:hotel_system_management/screens/widgets/list_query_bar.dart';

void main() {
  test('current hotel booking requires an active overlapping stay', () {
    final current = booking(
      checkIn: '2026-07-15',
      checkOut: '2026-07-18',
      status: 'confirmed',
    );
    final checkedOut = booking(
      checkIn: '2026-07-14',
      checkOut: '2026-07-16',
      status: 'confirmed',
    );
    final cancelled = booking(
      checkIn: '2026-07-15',
      checkOut: '2026-07-18',
      status: 'cancelled',
    );

    expect(isCurrentHotelBooking(current, DateTime(2026, 7, 16, 20)), isTrue);
    expect(isCurrentHotelBooking(checkedOut, DateTime(2026, 7, 16)), isFalse);
    expect(isCurrentHotelBooking(cancelled, DateTime(2026, 7, 16)), isFalse);
  });

  testWidgets('list query bar reports search sort and filter changes', (
    tester,
  ) async {
    String? query;
    String? sort;
    String? filter;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListQueryBar(
            searchHint: 'Search',
            onSearchChanged: (value) => query = value,
            sortValue: 'name',
            sortOptions: const {'name': 'Name', 'newest': 'Newest'},
            onSortChanged: (value) => sort = value,
            filterValue: 'all',
            filterOptions: const {'all': 'All', 'active': 'Active'},
            onFilterChanged: (value) => filter = value,
            resultCount: 3,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('listSearchField')),
      'room 101',
    );
    await tester.tap(find.byKey(const ValueKey('sort-name')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active').last);

    expect(query, 'room 101');
    expect(sort, 'newest');
    expect(filter, 'active');
  });

  testWidgets('invoice detail shows complete cost breakdown', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InvoiceDetailScreen(
          invoice: Invoice(
            invoiceId: 12,
            bookingId: 34,
            staffId: 5,
            issueDate: '2026-07-16T10:00:00.000Z',
            totalRoomCost: 1000000,
            totalServiceCost: 200000,
            discountAmount: 50000,
            finalAmount: 1265000,
            vatAmount: 115000,
            paymentMethod: 'PayOS',
            promotionId: 7,
            paymentStatus: 'paid',
          ),
        ),
      ),
    );

    expect(find.text('Hóa đơn #12'), findsOneWidget);
    expect(find.text('1.265.000 VNĐ'), findsAtLeastNWidgets(1));
    expect(find.text('PayOS'), findsOneWidget);
    expect(find.text('#34'), findsOneWidget);
  });

  test('room schedule filters cancelled and unrelated bookings', () {
    final matching = booking(
      checkIn: '2026-08-10',
      checkOut: '2026-08-12',
      status: 'confirmed',
    );
    final cancelled = booking(
      checkIn: '2026-08-01',
      checkOut: '2026-08-03',
      status: 'cancelled',
    );
    final unrelated = booking(
      checkIn: '2026-08-05',
      checkOut: '2026-08-06',
      status: 'confirmed',
      roomIds: const [202],
    );

    expect(bookingsForRoom([unrelated, cancelled, matching], 101), [matching]);
  });

  test('booking model reads room numbers separately from room ids', () {
    final value = Booking.fromJson({
      'booking_id': 1,
      'room_ids': [7, 8],
      'room_numbers': ['101', '202'],
    });

    expect(value.roomIds, [7, 8]);
    expect(value.roomNumbers, ['101', '202']);
  });

  testWidgets('room schedule shows check-in and check-out dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomBookingScheduleScreen(
          room: room(),
          loadBookings: () async => [
            booking(
              checkIn: '2026-08-10',
              checkOut: '2026-08-12',
              status: 'confirmed',
            ),
          ],
          loadCustomers: () async => [],
          loadPromotions: () async => [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check-in: 10/08/2026'), findsOneWidget);
    expect(find.text('Check-out: 12/08/2026'), findsOneWidget);
    expect(find.text('Booking #1'), findsOneWidget);
  });

  testWidgets('booking detail shows customer name and promotion percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookingDetailScreen(
          booking: booking(
            checkIn: '2026-08-10',
            checkOut: '2026-08-12',
            status: 'confirmed',
            promotionId: 9,
          ),
          customerName: 'Nguyễn Văn An',
          promotionDiscount: 15,
        ),
      ),
    );

    expect(find.text('Nguyễn Văn An'), findsAtLeastNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('Giảm 15% (Mã #9)'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Giảm 15% (Mã #9)'), findsOneWidget);
    expect(find.text('Username'), findsNothing);
  });
}

Booking booking({
  required String checkIn,
  required String checkOut,
  required String status,
  List<int> roomIds = const [101],
  List<String> roomNumbers = const ['101'],
  int? promotionId,
}) {
  return Booking(
    bookingId: 1,
    userId: 1,
    bookingDate: '2026-07-01',
    checkIn: checkIn,
    checkOut: checkOut,
    status: status,
    totalGuests: 2,
    promotionId: promotionId,
    numberOfDays: 3,
    numberOfNights: 3,
    totalPrice: 1000000,
    username: 'guest',
    roomIds: roomIds,
    roomNumbers: roomNumbers,
  );
}

Room room() {
  return Room(
    roomId: 101,
    roomNumber: '101',
    roomTypeId: 1,
    floor: 1,
    pricePerNight: 500000,
    maxGuests: 2,
    bedCount: 1,
    description: '',
    status: 'available',
    isActive: true,
    roomTypeName: 'Deluxe',
  );
}
