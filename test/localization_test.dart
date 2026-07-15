import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_system_management/core/localization/app_localizations.dart';
import 'package:hotel_system_management/core/models/user_model.dart';
import 'package:hotel_system_management/features/profile/view/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('switches profile from English to Vietnamese and saves locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var locale = const Locale('en');
    late StateSetter setRootState;
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
      StatefulBuilder(
        builder: (context, setState) {
          setRootState = setState;
          return MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: ProfileScreen(
              user: user,
              onUserUpdated: (_) {},
              onLogout: () async {},
              onLocaleChanged: (value) async {
                await AppLocaleStore.save(value);
                setRootState(() => locale = value);
              },
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vietnamese'));
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    expect((await AppLocaleStore.load()).languageCode, 'vi');
  });
}
