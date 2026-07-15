import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../home/view/home_screen.dart';
import 'account_screen.dart';

class CustomerShell extends StatefulWidget {
  final UserModel user;
  final Future<void> Function() onLogout;

  const CustomerShell({super.key, required this.user, required this.onLogout});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int selectedIndex = 0;

  void selectTab(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedIndex != 0) {
          selectTab(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: [
            HomeScreen(user: widget.user, onAccountTap: () => selectTab(1)),
            AccountScreen(user: widget.user, onLogout: widget.onLogout),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
