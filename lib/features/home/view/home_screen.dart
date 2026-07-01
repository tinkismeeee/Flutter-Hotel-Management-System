import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLoggedOut;

  const HomeScreen({super.key, required this.user, required this.onLoggedOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${user.firstName}'),
        actions: [
          IconButton(
            onPressed: () async {
              await UserModel.clearCurrentUser();
              onLoggedOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text('Logged in as ${user.email}')),
    );
  }
}
