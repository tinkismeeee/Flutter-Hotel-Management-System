import 'package:flutter/material.dart';
import 'features/home/view/home_screen.dart';
import 'features/login/controller/login_controller.dart';
import './features/login/view/login_screen.dart';
import 'core/models/user_model.dart';
import 'core/theme/app_theme.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/staff/staff_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final LoginController? loginController;

  const MyApp({super.key, this.loginController});

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

  Future<void> clearSession() async {
    await UserModel.clearCurrentUser();
    if (!mounted) return;
    setState(() {
      sessionUser = null;
    });
  }

  Widget homeForUser(UserModel user) {
    if (user.isAdmin) {
      return AdminScreen(onLogout: clearSession);
    }
    if (user.isStaff) {
      return StaffHomeScreen(onLogout: clearSession);
    }
    return HomeScreen(user: user);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
                  );
                }

                return homeForUser(user);
              },
            ),
    );
  }
}
