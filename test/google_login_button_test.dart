import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/features/login/view/widgets/google_login_button.dart';

void main() {
  testWidgets('native Google button keeps its key and invokes tap callback', (
    tester,
  ) async {
    var tapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleLoginButton(
            enabled: true,
            onTap: () => tapCalls++,
            onIdToken: (_) {},
            onError: (_) {},
          ),
        ),
      ),
    );

    final button = find.byKey(const Key('googleLoginButton'));
    expect(button, findsOneWidget);

    await tester.tap(button);

    expect(tapCalls, 1);
  });
}
