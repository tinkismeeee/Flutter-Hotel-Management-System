import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'features/login/controller/login_controller.dart';
import 'core/models/user_model.dart';
import 'core/theme/app_theme.dart';
import 'features/login/view/login_screen.dart';
import 'features/navigation/view/main_shell.dart';
import 'features/otp/controller/otp_controller.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/staff/staff_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final locale = await AppLocaleStore.load();
  runApp(MyApp(initialLocale: locale));
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final LoginController? loginController;
  final OtpController? otpController;

  const MyApp({
    super.key,
    this.initialLocale,
    this.loginController,
    this.otpController,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale locale;
  UserModel? sessionUser;

  @override
  void initState() {
    super.initState();
    locale = widget.initialLocale ?? const Locale('en');
  }

  void setSessionUser(UserModel user) {
    setState(() {
      sessionUser = user;
    });
  }

  void updateSessionUser(UserModel user) {
    setState(() {
      sessionUser = user;
    });
  }

  Future<void> clearSessionUser() async {
    await UserModel.clearCurrentUser();
    if (!mounted) return;
    setState(() {
      sessionUser = null;
    });
  }

  Widget homeForUser(UserModel user) {
    if (user.isAdmin) {
      return AdminScreen(onLogout: clearSessionUser);
    }
    if (user.isStaff) {
      return StaffHomeScreen(onLogout: clearSessionUser);
    }
    return MainShell(
      user: user,
      onLogout: clearSessionUser,
      onUserUpdated: updateSessionUser,
      onLocaleChanged: changeLocale,
    );
  }

  Future<void> changeLocale(Locale value) async {
    await AppLocaleStore.save(value);
    if (!mounted) return;
    setState(() => locale = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: sessionUser != null
          ? homeForUser(sessionUser!)
          : FutureBuilder<UserModel?>(
              future: UserModel.loadCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final user = snapshot.data;
                if (user == null) {
                  return LoginPage(
                    onLoggedIn: setSessionUser,
                    loginController: widget.loginController,
                    otpController: widget.otpController,
                  );
                }

                return homeForUser(user);
              },
            ),
    );
  }
}
