import 'package:flutter_test/flutter_test.dart';

import 'package:hotel_management_system/main.dart';

void main() {
  testWidgets('shows staff daily revenue action', (WidgetTester tester) async {
    await tester.pumpWidget(const HotelStaffApp());

    expect(find.text('KHU VỰC STAFF'), findsOneWidget);
    expect(find.text('Doanh thu ngày'), findsOneWidget);
  });
}
