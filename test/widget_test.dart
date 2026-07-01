import 'package:flutter_test/flutter_test.dart';

import 'package:hotel_management_system/main.dart';

void main() {
  testWidgets('shows staff home actions', (WidgetTester tester) async {
    await tester.pumpWidget(const HotelStaffApp());

    expect(find.text('KHU VỰC STAFF'), findsOneWidget);
    expect(find.text('Thông tin phòng'), findsOneWidget);
    expect(find.text('Dịch vụ'), findsOneWidget);
    expect(find.text('Mã giảm giá'), findsOneWidget);
    expect(find.text('Doanh thu ngày'), findsOneWidget);
  });
}
