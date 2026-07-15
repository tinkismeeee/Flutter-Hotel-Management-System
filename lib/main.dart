import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/models/user_model.dart';
import 'core/theme/app_theme.dart';
import 'features/login/view/login_screen.dart';
import 'features/navigation/view/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final locale = await AppLocaleStore.load();
  runApp(MyApp(initialLocale: locale));
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;

  const MyApp({super.key, required this.initialLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale locale;
  UserModel? sessionUser;

  @override
  void initState() {
    super.initState();
    locale = widget.initialLocale;
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
    if (!mounted) return;
    setState(() => sessionUser = null);
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
          ? MainShell(
              user: sessionUser!,
              onLogout: clearSessionUser,
              onUserUpdated: updateSessionUser,
              onLocaleChanged: changeLocale,
            )
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
                  return LoginPage(onLoggedIn: setSessionUser);
                }

                return MainShell(
                  user: user,
                  onLogout: clearSessionUser,
                  onUserUpdated: updateSessionUser,
                  onLocaleChanged: changeLocale,
                );
              },
            ),
    );
  }
}
