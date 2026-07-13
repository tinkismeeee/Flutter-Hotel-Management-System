import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/screens/room/room_form_values.dart';
import 'package:hotel_system_management/services/api_response.dart';

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
}
