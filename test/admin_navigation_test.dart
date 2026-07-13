import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/screens/admin/admin_screen.dart';

void main() {
  testWidgets('admin logout returns through the app logout callback', (
    tester,
  ) async {
    var loggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminScreen(onLogout: () async => loggedOut = true),
                  ),
                );
              },
              child: const Text('Open admin'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open admin'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(GridView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
    expect(find.text('Open admin'), findsOneWidget);
  });
}
