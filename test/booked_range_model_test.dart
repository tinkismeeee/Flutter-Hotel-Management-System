import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/booked_range_model.dart';

void main() {
  final range = BookedRangeModel.fromJson({
    'check_in': '2026-08-10T00:00:00.000Z',
    'check_out': '2026-08-12T00:00:00.000Z',
  });

  test('checkout date is not blocked', () {
    expect(range.contains(DateTime(2026, 8, 10)), isTrue);
    expect(range.contains(DateTime(2026, 8, 11)), isTrue);
    expect(range.contains(DateTime(2026, 8, 12)), isFalse);
  });

  test('adjacent stay does not overlap', () {
    expect(
      range.overlaps(DateTime(2026, 8, 8), DateTime(2026, 8, 10)),
      isFalse,
    );
    expect(range.overlaps(DateTime(2026, 8, 9), DateTime(2026, 8, 11)), isTrue);
  });
}
