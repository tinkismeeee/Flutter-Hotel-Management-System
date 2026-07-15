import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/home/view/home_screen.dart';
import 'package:hotel_system_management/features/login/view/login_screen.dart';
import 'package:hotel_system_management/main.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('customer shell switches tabs without rebuilding Home', (
    tester,
  ) async {
    final user = _customer();
    await UserModel.saveCurrentUser(user);
    await _pumpCustomerApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    final homeState = tester.state(find.byType(HomeScreen));

    await tester.tap(find.text('Account'));
    await tester.pump();

    expect(find.text(user.username), findsOneWidget);
    expect(find.text(user.email), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pump();

    expect(tester.state(find.byType(HomeScreen)), same(homeState));
  });

  testWidgets('customer header identity opens Account', (tester) async {
    final user = _customer(
      username: 'linhtran',
      email: 'linh@example.com',
      firstName: 'Linh',
      lastName: 'Tran',
    );
    await UserModel.saveCurrentUser(user);
    await _pumpCustomerApp(tester);

    await tester.tap(find.byKey(const Key('customerHeaderAccountButton')));
    await tester.pump();

    expect(find.text('Linh Tran'), findsOneWidget);
    expect(find.text(user.email), findsOneWidget);
    expect(find.text('LT'), findsOneWidget);
  });

  testWidgets('system Back from Account selects Home', (tester) async {
    await UserModel.saveCurrentUser(_customer());
    await _pumpCustomerApp(tester);

    await tester.tap(find.text('Account'));
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('customer logout clears persisted session and stays logged out', (
    tester,
  ) async {
    await UserModel.saveCurrentUser(_customer());
    await _pumpCustomerApp(tester);

    await tester.tap(find.text('Account'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('customerLogoutButton')));
    await tester.pump();
    await tester.pump();

    expect(await UserModel.loadCurrentUser(), isNull);
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}

Future<void> _pumpCustomerApp(WidgetTester tester) async {
  await http.runWithClient(
    () async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
    () => MockClient((request) async {
      if (request.url.host == 'api.unsplash.com') {
        return http.Response('{"results":[]}', 200);
      }
      return http.Response('[]', 200);
    }),
  );
}

UserModel _customer({
  String username = 'customer',
  String email = 'customer@example.com',
  String firstName = '',
  String lastName = '',
}) {
  return UserModel(
    userId: 'customer',
    username: username,
    email: email,
    password: '',
    firstName: firstName,
    lastName: lastName,
    phone: '',
    address: '',
    dateOfBirth: '',
  );
}
