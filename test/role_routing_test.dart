import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/home/view/home_screen.dart';
import 'package:hotel_system_management/features/login/controller/login_controller.dart';
import 'package:hotel_system_management/features/login/view/login_screen.dart';
import 'package:hotel_system_management/features/otp/controller/otp_controller.dart';
import 'package:hotel_system_management/features/otp/view/otp_screen.dart';
import 'package:hotel_system_management/main.dart';
import 'package:hotel_system_management/screens/admin/admin_screen.dart';
import 'package:hotel_system_management/screens/staff/staff_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final role in <({String name, UserModel user, Type screen})>[
    (name: 'admin', user: _user(isAdmin: true), screen: AdminScreen),
    (name: 'staff', user: _user(isStaff: true), screen: StaffHomeScreen),
    (name: 'customer', user: _user(), screen: HomeScreen),
  ]) {
    testWidgets('restored ${role.name} session opens ${role.screen}', (
      tester,
    ) async {
      await UserModel.saveCurrentUser(role.user);

      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(role.screen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    if (role.name == 'customer') continue;

    testWidgets('${role.name} login opens ${role.screen}', (tester) async {
      await tester.pumpWidget(
        MyApp(loginController: _RoleLoginController(role.user)),
      );
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), role.user.email);
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(role.screen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
  }

  testWidgets('customer password login opens OTP before Home', (tester) async {
    await tester.pumpWidget(
      MyApp(
        loginController: _RoleLoginController(_user()),
        otpController: _SuccessfulOtpController(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'customer@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('staff logout clears session and returns to login', (
    tester,
  ) async {
    await UserModel.saveCurrentUser(_user(isStaff: true));

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('staffLogoutButton')));
    await tester.pump();
    await tester.pump();

    expect(await UserModel.loadCurrentUser(), isNull);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('customer home does not expose admin navigation', (tester) async {
    await UserModel.saveCurrentUser(_user());

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip('Administration'), findsNothing);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.routes?.containsKey('/admin') ?? false, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

UserModel _user({bool isAdmin = false, bool isStaff = false}) {
  return UserModel(
    userId: isAdmin ? 'admin' : (isStaff ? 'staff' : 'customer'),
    username: isAdmin ? 'admin' : (isStaff ? 'staff' : 'customer'),
    email: isAdmin
        ? 'admin'
        : (isStaff ? 'staff@example.com' : 'customer@example.com'),
    password: '',
    firstName: '',
    lastName: '',
    phone: '',
    address: '',
    dateOfBirth: '',
    isAdmin: isAdmin,
    isStaff: isStaff,
  );
}

class _RoleLoginController extends LoginController {
  final UserModel user;

  _RoleLoginController(this.user);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberPassword,
  }) async {
    return user;
  }
}

class _SuccessfulOtpController extends OtpController {
  @override
  Future<String> sendOtp(String email) async => 'OTP sent';
}
