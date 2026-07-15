import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/profile/view/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('profile shows available API data and logs out', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({'current_user': '{"user_id":"7"}'});
    var loggedOut = false;
    final user = UserModel(
      userId: '7',
      username: 'brooklyn',
      email: 'brooklyn@example.com',
      password: '',
      firstName: 'Brooklyn',
      lastName: 'Simmons',
      phone: '',
      address: '',
      dateOfBirth: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          user: user,
          onUserUpdated: (_) {},
          onLogout: () async {
            loggedOut = true;
          },
        ),
      ),
    );

    expect(find.text('Brooklyn Simmons'), findsOneWidget);
    expect(find.text('@brooklyn'), findsOneWidget);
    expect(find.text('brooklyn@example.com'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Not provided'), findsNWidgets(3));

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
  });
}
