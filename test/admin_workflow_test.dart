import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/screens/room/room_form_values.dart';
import 'package:hotel_system_management/services/api_response.dart';
import 'package:hotel_system_management/models/promotion.dart';
import 'package:hotel_system_management/screens/promotion/edit_promotion_screen.dart';

void main() {
  test('room form accepts positive numeric values', () {
    final values = RoomFormValues.tryParse(
      floor: '4',
      pricePerNight: '1000.00',
      maxGuests: '2',
      bedCount: '2',
    );

    expect(values, isNotNull);
    expect(values!.floor, 4);
    expect(values.pricePerNight, 1000);
  });

  test('room form rejects invalid or non-positive values', () {
    expect(
      RoomFormValues.tryParse(
        floor: 'x',
        pricePerNight: '1000',
        maxGuests: '2',
        bedCount: '2',
      ),
      isNull,
    );
    expect(
      RoomFormValues.tryParse(
        floor: '1',
        pricePerNight: '0',
        maxGuests: '2',
        bedCount: '2',
      ),
      isNull,
    );
  });

  test('HTTP mutation success accepts the full 2xx range', () {
    expect(isSuccessfulStatus(200), isTrue);
    expect(isSuccessfulStatus(201), isTrue);
    expect(isSuccessfulStatus(204), isTrue);
    expect(isSuccessfulStatus(299), isTrue);
    expect(isSuccessfulStatus(300), isFalse);
    expect(isSuccessfulStatus(500), isFalse);
  });

  testWidgets('promotion editor accepts the live all scope', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditPromotionScreen(
          promotion: Promotion(
            promotionId: 1,
            promotionCode: 'PROMO10',
            name: 'New Year Discount',
            discountValue: 10,
            startDate: '1990-01-01T00:00:00.000Z',
            endDate: '2100-02-01T00:00:00.000Z',
            isActive: true,
            scope: 'all',
            description: '10% off all invoice',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('all'), findsOneWidget);
  });
}
