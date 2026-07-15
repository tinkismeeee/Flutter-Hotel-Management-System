import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/payos_payment_model.dart';
import 'package:hotel_system_management/core/models/room_model.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/payment/view/payment_qr_screen.dart';

void main() {
  testWidgets('paid booking can return My Booking flow to Home', (
    tester,
  ) async {
    var homeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentQrScreen(
          room: const RoomModel(
            roomId: 1,
            roomNumber: '101',
            roomTypeId: 1,
            floor: 1,
            pricePerNight: '100000',
            maxGuests: 2,
            bedCount: 1,
            description: '',
            status: 'available',
            isActive: true,
            roomTypeName: 'Standard',
          ),
          user: UserModel(
            userId: '1',
            username: 'customer',
            email: 'customer@example.com',
            password: '',
            firstName: 'Test',
            lastName: 'Customer',
            phone: '',
            address: '',
            dateOfBirth: '',
          ),
          payment: const PayOsPaymentModel(
            bookingId: 1,
            orderCode: 1,
            amount: 100000,
            status: 'paid',
            checkoutUrl: '',
            qrCode: '',
            expiresAt: null,
          ),
          onBackToHome: () => homeCalls++,
        ),
      ),
    );
    await tester.pump();

    final backToHome = find.widgetWithText(ElevatedButton, 'Back to home');
    await tester.ensureVisible(backToHome);
    await tester.tap(backToHome);
    await tester.pump();

    expect(homeCalls, 1);
  });
}
