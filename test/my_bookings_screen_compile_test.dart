import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/bookings/view/my_bookings_screen.dart';

void main() {
  test('my bookings screen compiles', () {
    final screen = MyBookingsScreen(
      user: UserModel(
        userId: '1',
        username: 'guest',
        email: 'guest@example.com',
        password: '',
        firstName: 'Guest',
        lastName: 'User',
        phone: '',
        address: '',
        dateOfBirth: '',
      ),
    );

    expect(screen.refreshToken, 0);
  });
}
