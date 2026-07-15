import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/const/api_endpoints.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/customer/view/account_screen.dart';
import 'package:hotel_system_management/features/customer/view/my_profile_screen.dart';
import 'package:hotel_system_management/services/customer_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const customerJson = <String, dynamic>{
    'user_id': 42,
    'username': 'latest-user',
    'email': 'latest@example.com',
    'first_name': 'Latest',
    'last_name': 'Customer',
    'phone_number': '0909000111',
    'address': 'Ho Chi Minh City',
    'date_of_birth': '1995-04-03',
    'is_active': true,
  };

  test(
    'getCustomerById uses the exact customer URL and parses the response',
    () async {
      late http.Request capturedRequest;

      final customer = await http.runWithClient(
        () => CustomerService.getCustomerById('42'),
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode(customerJson), 200);
        }),
      );

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.toString(), ApiEndpoints.customerById('42'));
      expect(customer.userId, 42);
      expect(customer.username, 'latest-user');
      expect(customer.email, 'latest@example.com');
      expect(customer.firstName, 'Latest');
      expect(customer.lastName, 'Customer');
      expect(customer.phoneNumber, '0909000111');
      expect(customer.address, 'Ho Chi Minh City');
      expect(customer.dateOfBirth, '1995-04-03');
    },
  );

  testWidgets('Account opens My Profile', (tester) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccountScreen(user: _user(), onLogout: () async {}),
            ),
          ),
        );

        final profileButton = find.byKey(const Key('myProfileButton'));
        await tester.ensureVisible(profileButton);
        await tester.pump();
        tester.widget<ListTile>(profileButton).onTap!();
        await tester.pumpAndSettle();

        expect(find.byType(MyProfileScreen), findsOneWidget);
      },
      () => MockClient(
        (request) async => http.Response(jsonEncode(customerJson), 200),
      ),
    );
  });

  testWidgets('My Profile shows loading and renders placeholders', (
    tester,
  ) async {
    final response = Completer<http.Response>();

    await http.runWithClient(() async {
      await tester.pumpWidget(
        const MaterialApp(home: MyProfileScreen(userId: '42')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      response.complete(
        http.Response(
          jsonEncode({
            ...customerJson,
            'phone_number': '',
            'address': null,
            'date_of_birth': '   ',
          }),
          200,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('latest-user'), findsOneWidget);
      expect(find.text('latest@example.com'), findsOneWidget);
      expect(find.text('Latest Customer'), findsOneWidget);
      expect(find.text('Not updated'), findsNWidgets(3));
    }, () => MockClient((request) => response.future));
  });

  testWidgets('My Profile retries a failed API request', (tester) async {
    var attempts = 0;

    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(home: MyProfileScreen(userId: '42')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unable to load profile'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('latest-user'), findsOneWidget);
        expect(attempts, 2);
      },
      () => MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('Server unavailable', 503);
        }
        return http.Response(jsonEncode(customerJson), 200);
      }),
    );
  });

  testWidgets('My Profile keeps existing content visible while refreshing', (
    tester,
  ) async {
    var attempts = 0;
    final refreshResponse = Completer<http.Response>();

    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(home: MyProfileScreen(userId: '42')),
        );
        await tester.pumpAndSettle();

        expect(find.text('latest-user'), findsOneWidget);

        await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(attempts, 2);
        expect(find.text('latest-user'), findsOneWidget);

        refreshResponse.complete(
          http.Response(
            jsonEncode({...customerJson, 'username': 'refreshed-user'}),
            200,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('refreshed-user'), findsOneWidget);
      },
      () => MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response(jsonEncode(customerJson), 200);
        }
        return refreshResponse.future;
      }),
    );
  });
}

UserModel _user() {
  return UserModel(
    userId: '42',
    username: 'cached-user',
    email: 'cached@example.com',
    password: '',
    firstName: 'Cached',
    lastName: 'Customer',
    phone: '',
    address: '',
    dateOfBirth: '',
  );
}
