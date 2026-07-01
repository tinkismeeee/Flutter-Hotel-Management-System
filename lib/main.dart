import 'package:flutter/material.dart';
import 'features/home/view/home_screen.dart';
import './features/login/view/login_screen.dart';
import 'core/models/user_model.dart';
import 'core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: sessionUser != null
          ? HomeScreen(user: sessionUser!)
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

                return HomeScreen(user: user);
              },
            ),
    );
  }
}
