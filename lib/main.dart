import 'package:flutter/material.dart';
import './features/login/view/login_screen.dart';
import 'core/models/user_model.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/view/main_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UserModel? sessionUser;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: sessionUser != null
          ? MainShell(
              user: sessionUser!,
              onLogout: clearSessionUser,
              onUserUpdated: updateSessionUser,
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
                );
              },
            ),
    );
  }
}
