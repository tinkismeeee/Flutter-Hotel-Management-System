import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/features/login/controller/login_controller.dart';
import 'package:hotel_system_management/features/login/view/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Google button logs in and reports the returned user', (
    tester,
  ) async {
    final controller = LoginController(
      googleTokenProvider: () async => 'google-id-token',
      post: (uri, {headers, body, encoding}) async => http.Response(
        jsonEncode({
          'message': 'Login successful',
          'user': {
            'user_id': '42',
            'username': 'google-user',
            'email': 'google@example.com',
            'is_active': true,
          },
        }),
        200,
      ),
    );
    String? loggedInEmail;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          loginController: controller,
          onLoggedIn: (user) => loggedInEmail = user.email,
        ),
      ),
    );

    final googleButton = find.byKey(const Key('googleLoginButton'));
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(loggedInEmail, 'google@example.com');
  });

  testWidgets('Google cancellation exits without a visible error', (
    tester,
  ) async {
    final controller = LoginController(
      googleTokenProvider: () async => throw const GoogleLoginCanceled(),
      post: (uri, {headers, body, encoding}) async =>
          throw StateError('HTTP must not run'),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(loginController: controller)),
    );

    final googleButton = find.byKey(const Key('googleLoginButton'));
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('canceled'), findsNothing);
    expect(tester.widget<GestureDetector>(googleButton).onTap, isNotNull);
  });

  testWidgets('disposed login page does not report a pending Google login', (
    tester,
  ) async {
    final token = Completer<String>();
    var callbackCalls = 0;
    final controller = LoginController(
      googleTokenProvider: () => token.future,
      post: (uri, {headers, body, encoding}) async => http.Response(
        jsonEncode({
          'message': 'Login successful',
          'user': {
            'user_id': '42',
            'username': 'google-user',
            'email': 'google@example.com',
            'is_active': true,
          },
        }),
        200,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          loginController: controller,
          onLoggedIn: (_) => callbackCalls++,
        ),
      ),
    );

    final googleButton = find.byKey(const Key('googleLoginButton'));
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    token.complete('google-id-token');
    await tester.pumpAndSettle();

    expect(callbackCalls, 0);
  });
}
