import 'package:flutter/material.dart';
import 'features/home/view/home_screen.dart';
import './features/login/view/login_screen.dart';
import 'core/models/user_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int sessionVersion = 0;
  UserModel? sessionUser;

  void setSessionUser(UserModel user) {
    setState(() {
      sessionUser = user;
    });
  }

  void clearSessionUser() {
    setState(() {
      sessionUser = null;
      sessionVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: sessionUser != null
          ? HomeScreen(user: sessionUser!, onLoggedOut: clearSessionUser)
          : FutureBuilder<UserModel?>(
              key: ValueKey(sessionVersion),
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

                return HomeScreen(user: user, onLoggedOut: clearSessionUser);
              },
            ),
    );
  }
}
