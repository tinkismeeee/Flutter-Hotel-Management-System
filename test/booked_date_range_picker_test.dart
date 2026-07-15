import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/booked_range_model.dart';
import 'package:hotel_system_management/features/detail_rooms/view/widgets/booked_date_range_picker.dart';

void main() {
  testWidgets('shows a red dot on each booked night', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookedDateRangePickerDialog(
            firstDate: DateTime(2026, 8, 1),
            lastDate: DateTime(2026, 9, 1),
            bookedRanges: [
              BookedRangeModel(
                checkIn: DateTime(2026, 8, 10),
                checkOut: DateTime(2026, 8, 12),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('booked-dot-2026-8-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('booked-dot-2026-8-11')), findsOneWidget);
    expect(find.byKey(const ValueKey('booked-dot-2026-8-12')), findsNothing);
  });
}
